# == Schema Information
#
# Table name: cohort_collectors
#
#  id         :bigint           not null, primary key
#  index_name :string
#  keywords   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CohortCollector < ApplicationRecord
  has_and_belongs_to_many :search_queries
  validates :search_queries, presence: true
  after_create :initialize_keywords
  after_create :add_index_name

  # - collects data for a given set of queries
  #   - knows how to initialize the data run, stop, start
  #   - this means that CohortCollector.new.run_pipeline is a thing that a cron job can call
  # - for each query, builds a Cohort
  #   - therefore it knows how to sample
  #   - and how to create a description from a SearchQuery

  # This will need something very different to run for a week, but at the moment
  # let's just get it running at all.
  def start_monitoring
    # make a twitterconf, using that index name
    # initiate the logstash with timeout
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
    usable_ids = user_ids.uniq.sample(Rails.application.config.num_users)
    usable_ids.map(&:to_i)
  end

  def create_cohort
    Cohort.create(
      twitter_ids: sample_users,
      description: "Twitter users talking about #{keywords} in the week before #{Date.today}"
    )
  end

  private

  def es_client
    @es_client ||= Elasticsearch::Client.new
  end

  def extract_userids(results)
    # See https://developer.twitter.com/en/docs/tweets/data-dictionary/overview/tweet-object
    # for the inside of the block. The ['hits']['hits'] comes from the structure
    # of elasticsearch objects; the tweet objects returned from the API are
    # wrapped in metadata, and we need to extract them.
    results['hits']['hits'].map { |r| r['_source']['user']['id_str'] }.uniq
  end

  # This freezes the keywords as they existed at the time of the configuration,
  # to aid in debugging. It also allows for collaborators to query
  # CohortCollector directly for keywords rather than reaching through it to
  # SearchQuery.
  def initialize_keywords
    self.keywords = search_queries.pluck(:keyword)
  end

  def add_index_name
    self.index_name = "user_run_#{self.id}_#{sanitize(SecureRandom.uuid)}"
  end
end
