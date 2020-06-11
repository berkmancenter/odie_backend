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
#  index_tweet_fetchers_on_complete     (complete)
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

  before_create :set_backoff

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

  def set_backoff
    enqueued = TweetFetcher.where(complete: false).count
    limit = Rails.configuration.rate_limit_limit * 0.95 # safety margin
    window = Rails.configuration.rate_limit_window * 60 # convert to seconds

    # This messy exponential:
    # - sets backoff to 0 (i.e. execute task immediately) when we have fewer
    # than half of our limit in the queue
    # - sets the backoff to the entire window size when the enqueued is near
    # (95% of) our limit
    # - in between, biases toward the shorter end, via exponential decay
    # This means that when cohorts are small, we'll grab all the data as quickly
    # as possible. When they're medium-sized, we'll still be pretty fast. As
    # the cohort size approaches the limit, the time to fetch all data will
    # approach the window size. When the cohort size is near or above the limit,
    # the time to fetch all data will exceed the window size, in order to avoid
    # rate limiting.
    # In addition, since this looks at all enqueued TweetFetchers and not just
    # those belonging to a given DataSet, when we are fetching data for multiple
    # DataSets at once, they will cooperate to avoid hitting the window.
    self.backoff = max(2*window - (2^(-2*enqueued/limit))*4*window, 0)
  end
end
