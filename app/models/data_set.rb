# == Schema Information
#
# Table name: data_sets
#
#  id              :bigint           not null, primary key
#  index_name      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  data_config_id  :bigint
#  media_source_id :bigint
#
# Indexes
#
#  index_data_sets_on_data_config_id   (data_config_id)
#  index_data_sets_on_media_source_id  (media_source_id)
#
# Foreign Keys
#
#  fk_rails_...  (data_config_id => data_configs.id)
#

class DataSet < ApplicationRecord
  belongs_to :media_source
  belongs_to :data_config

  validates :media_source, presence: true
  validates :data_config, presence: true

  attr_readonly :index_name
  before_create :add_index_name

  def ingest_data
    verify_index
    sample_users.each do |user_id|
      tweets = fetch_tweets(user_id)
      store_data(tweets)
    end
  end

  def sample_users
    # TODO: improve semantics
    # We've filtered our incoming data to only include tweets with the correct
    # keyword in the expanded_url field, but that doesn't mean this search
    # actually produces only tweets which link to the relevant source; they
    # might @mention the keyword and link to a different media source, e.g., as
    # in "hey @newspaper did you see this article? https://www.blog.com".
    results = es_client.search index: stream_index, q: media_source.keyword
    user_ids = extract_userids(results)
    user_ids.sample(Rails.application.config.num_users)
  end

  def index_exists?
    es_client.indices.exists? :index_name
  end

  def fetch_tweets(user_id)
    # logstash only uses the streaming api, not the user timeline api. oy.
    # so we're going to need to create an elasticsearch index with the
    # usual mapping and dump this in..?
    tweets = twitter_client.user_timeline(
      user_id,
      count: Rails.application.config.tweets_per_user
    )
  end

  def store_data(tweets)
    tweets.each do |tweet|
      es_client.create index: index_name, type: 'tweets', body: tweet.to_json
    end
  end

  private

  def es_client
    @es_client ||= Elasticsearch::Client.new
  end

  def twitter_client
    @twitter_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
      config.access_token_secret = ENV['TWITTER_OAUTH_SECRET']
    end
  end

  def extract_userids(results)
    # See https://developer.twitter.com/en/docs/tweets/data-dictionary/overview/tweet-object
    # for the inside of the block. The ['hits']['hits'] comes from the structure
    # of elasticsearch objects; the tweet objects returned from the API are
    # wrapped in metadata, and we need to extract them.
    results['hits']['hits'].map { |r| r['_source']['user']['id_str'] }.uniq
  end

  def add_index_name
    self.index_name = "#{self.media_source.id}_#{sanitize(SecureRandom.uuid)}"
  end

  # Remove any elements not permitted in elasticsearch index names:
  # https://www.elastic.co/guide/en/elasticsearch/reference/6.6/indices-create-index.html
  def sanitize(str)
    str.gsub(%r{[\\/*?"<>|\s,#]:}, '').downcase
  end

  def setup_index
    es_client.indices.create index: index_name,
      body: Rails.application.config.twitter_template
  end

  # We could do this on_create, but that wouldn't guarantee that it continued
  # to exist at time of use. Also, it would couple DataSet creation to the
  # availability of an Elasticsearch service, which would make development and
  # testing challenging.
  def verify_index
    setup_index unless index_exists?
    raise Exceptions::ElasticsearchError('Index not found') unless index_exists?
  end

  # This is the index that stored the results of the streaming API call to
  # search for references to media sources. It is distinct from self.index_name,
  # which is where we store user timeline results (ie all the tweets of users
  # whom we found in the earlier streaming api call.)
  def stream_index
    data_config.index_name
  end
end
