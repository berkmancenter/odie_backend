# frozen_string_literal: true

# == Schema Information
#
# Table name: data_sets
#
#  id           :bigint           not null, primary key
#  hashtags     :hstore
#  index_name   :string
#  num_retweets :integer
#  num_tweets   :integer
#  num_users    :integer
#  top_mentions :hstore
#  top_sources  :hstore
#  top_urls     :hstore
#  top_words    :hstore
#  unauthorized :text             default([]), is an Array
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  cohort_id    :bigint
#
# Indexes
#
#  index_data_sets_on_cohort_id  (cohort_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#

class DataSet < ApplicationRecord
  belongs_to :cohort
  has_many :retweets

  attr_readonly :index_name
  before_create :add_index_name

  def run_pipeline
    verify_index
    ingest_data
    update_aggregates
  end

  # Known bugs:
  # we automatically take the top 5 from the collation -- might want that to be
  # configurable
  # we discard ties in that last position
  # might prefer TF-IDF to simple word count
  # generic stopword filter (plus 'RT') -- might not be what we prefer
  # default to English when language is unknown
  def update_aggregates
    es_client.indices.refresh index: index_name
    self.update_attributes(
      num_users: cohort.twitter_ids.length,
      num_tweets: es_client.count(index: index_name)['count'],
      num_retweets: count_retweets,
      hashtags: MetadataHarvester.new(:hashtags, all_tweets).harvest,
      top_urls: MetadataHarvester.new(:urls, all_tweets).harvest,
      top_words: MetadataHarvester.new(:words, all_tweets).harvest,
      top_mentions: MetadataHarvester.new(:mentions, all_tweets).harvest,
      top_sources: MetadataHarvester.new(:sources, all_tweets).harvest,
      unauthorized: unauthorized_ids
    )
    create_retweets
  end

  def ingest_data
    cohort.twitter_ids.each do |user_id|
      tweets = fetch_tweets(user_id)
      store_data(tweets)
      all_tweets << tweets
    rescue Twitter::Error::Unauthorized
      unauthorized_ids << user_id
    end
  end

  def index_exists?
    es_client.indices.exists? index: index_name
  end

  def fetch_tweets(user_id)
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
      es_client.create index: index_name, type: '_doc', body: tweet.to_json
    end
  end

  # This aggregates data from multiple DataSet instances. It does NOT aggregate
  # the num_whatevers as there is no way to deduplicate those.
  def self.aggregate(ids)
    # Why, oh why, did I use different names for data set attributes and
    # MetadataHarvester options. And yet, here we are.
    data_sets_to_extractors = {
      hashtags: :hashtags,
      top_urls: :urls,
      top_words: :words,
      top_mentions: :mentions,
      top_sources: :sources,
      top_retweets: :retweets
    }
    data_sets = self.where(id: ids)

    retval = {}

    data_sets_to_extractors.each do |dataset_key, extractor_key|
      data = MetadataHarvester.new(extractor_key, [])
                              .accumulate(data_sets)
                              .harvest

      retval[dataset_key] = data
    end

    retval
  end

  def top_retweets
    top = {}
    self.retweets.map do |item|
      top[item[:text]] = { count: item[:count], link: item[:link] }
    end
    top
  end

  private

  def all_tweets
    @all_tweets ||= []
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

  def add_index_name
    self.index_name = IndexName.new("dataset_#{self.id}").generate
  end

  def setup_index
    return if index_exists?
    es_client.indices.create index: index_name,
      body: IO.read(Rails.application.config.twitter_template)
  end

  # We could do this on_create, but that wouldn't guarantee that it continued
  # to exist at time of use. Also, it would couple DataSet creation to the
  # availability of an Elasticsearch service, which would make development and
  # testing challenging.
  def verify_index
    setup_index
    raise Exceptions::ElasticsearchError('Index not found') unless index_exists?
  end

  def count_retweets
    results = es_client.count index: index_name,
                body: { query: { exists: { field: 'retweeted_status' } } }
    results['count']
  end

  # We have a Retweet object, rather than storing this data in a postgres
  # hstore, because hstore doesn't deal well with nested hashes. However, we
  # need nested hashes for retweets in order to keep track of more than 2 data
  # elements (not just text and count, but also link -- we want to be able
  # to display links on the front end).
  def create_retweets
    # Nested retweets goes to their own table
    MetadataHarvester.new(:retweets, all_tweets).harvest.each do |text, retweet|
      Retweet.create!(
        data_set: self,
        text: text,
        count: retweet[:count],
        link: retweet[:link]
      )
    end
  end

  # We may find at runtime that some of the accounts we want to monitor are
  # no longer public; we'll keep a record of them here.
  def unauthorized_ids
    @unauthorized_ids ||= []
  end
end
