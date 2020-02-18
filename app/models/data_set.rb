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
#  top_retweets :hstore
#  top_sources  :hstore
#  top_urls     :hstore
#  top_words    :hstore
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
      top_retweets: MetadataHarvester.new(:retweets, all_tweets).harvest
    )
  end

  def ingest_data
    cohort.twitter_ids.each do |user_id|
      tweets = fetch_tweets(user_id)
      store_data(tweets)
      all_tweets << tweets
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
    keys = %i[hashtags top_urls top_words top_mentions top_sources top_retweets]
    data_sets = self.where(id: ids)
    retval = {}

    keys.each do |key|
      # Accumulate data from all datasets in scope.
      data = data_sets.pluck(key)
                      .map { |h| h.transform_values!(&:to_i) }
                      .reduce ({}) do |first, second|
                        first.merge(second) { |_, a, b| a + b }
                      end

      # Keep only the data above our thresholds.
      min_count = data.values.sort.last(Extractor::TOP_N)[0]
      data.reject! { |k, v| v < [min_count, Extractor::THRESHOLD].max }

      retval[key] = data
    end

    retval
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
    self.index_name = "#{self.cohort.id}_#{sanitize(SecureRandom.uuid)}"
  end

  # Remove any elements not permitted in elasticsearch index names:
  # https://www.elastic.co/guide/en/elasticsearch/reference/6.6/indices-create-index.html
  def sanitize(str)
    str.gsub(%r{[\\/*?"<>|\s,#]:}, '').downcase
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
end
