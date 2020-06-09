# frozen_string_literal: true

# == Schema Information
#
# Table name: tweet_fetchers
#
#  id          :bigint           not null, primary key
#  backoff     :integer          default(1)
#  complete    :boolean          default(FALSE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  data_set_id :bigint
#  user_id     :string
#
# Indexes
#
#  index_tweet_fetchers_on_data_set_id  (data_set_id)
#
# Foreign Keys
#
#  fk_rails_...  (data_set_id => data_sets.id)
#

# TweetFetcher fetches tweets for a single user. One DataSet spawns many
# TweetFetchers, one per user_id in the cohort. This allows us to execute
# tweet fetching out-of-band, so that we can be sensitive to rate limits.
# When all of a DataSet's TweetFetchers are complete, the DataSet can be
# finalized.
class TweetFetcher < ApplicationRecord
  belongs_to :data_set

  def ingest
    store_data(fetch_tweets)
    # Make sure to mark this complete _before_ calling finish_when_ready, as
    # finish_when_ready will check to see if all the data_set's TweetFetchers
    # are complete!
    self.update_attributes(complete: true)
    data_set.finish_when_ready
  rescue Twitter::Error::Unauthorized
    data_set.unauthorized << user_id
    data_set.save
    self.update_attributes(complete: true)
  end

  private

  def fetch_tweets
    # logstash only uses the streaming api, not the user timeline api. oy.
    # so we're going to need to create an elasticsearch index with the
    # usual mapping and dump this in..?
    twitter_client.user_timeline(
      user_id.to_i,
      count: Rails.application.config.tweets_per_user,
      tweet_mode: 'extended'
    )
  end

  def store_data(tweets)
    tweets.each do |tweet|
      es_client.create index: data_set.index_name,
                       type: '_doc',
                       body: tweet.to_json
    end
  end

  def twitter_client
    @twitter_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
      config.access_token_secret = ENV['TWITTER_OAUTH_SECRET']
    end
  end

  def es_client
    @es_client ||= Elasticsearch::Client.new
  end
end
