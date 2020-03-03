# == Schema Information
#
# Table name: cohort_collectors
#
#  id         :bigint           not null, primary key
#  end_time   :datetime
#  index_name :string
#  keywords   :text             default([]), is an Array
#  start_time :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CohortCollector < ApplicationRecord
  has_and_belongs_to_many :search_queries
  validates :search_queries, presence: true
  after_create :initialize_keywords
  after_create :add_index_name

  def monitor_twitter
    unless services_available?
      Rails.logger.warn('Cannot monitor twitter because services are not available')
      return false
    end

    datarun = StreamingDataCollector.new(self)
    datarun.write_conf
    datarun.kickoff
    self.update_attributes({
      end_time: Time.now + CohortCollector.logstash_run_time.seconds,
      start_time: Time.now})

    true
  end

  def create_cohort
    return unless creation_permissible?

    Cohort.create(
      twitter_ids: sample_users,
      description: "Twitter users talking about #{keywords} between #{readable_date(start_time)} and #{readable_date(end_time)}"
    )
  end

  def sample_users
    results = es_client.search index: index_name, _source: ['id_str']
    ids = results['hits']['hits'].map { |hit| hit['_source']['id_str'] }
    ids.uniq.sample(Rails.application.config.num_users)
  end

  # In the config, logstash_run_time is specified in a format suitable for the
  # linux timeout command, but we need it in a ruby-friendly format. This
  # converts logstash_run_time into an integer (number of seconds).
  def self.logstash_run_time
    match = Rails.application.config.logstash_run_time.match(/^([0-9]+)([s|m|d|h])$/)
    raise 'logstash_run_time incorrectly formatted' unless match.present?

    amount = match.captures.first.to_i
    unit = match.captures.second

    case unit
    when 's'
      amount
    when 'm'
      amount * 60
    when 'h'
      amount * 3600
    when 'd'
      amount * 86400
    end
  end

  def readable_date(date)
    date.strftime('%e %B %Y')
  end

  def readable_time(date)
    # Yes, we're assuming admin users are in Eastern time.
    date.in_time_zone('Eastern Time (US & Canada)')
        .strftime('%k:%M %p on %e %B %Y')
        .squeeze
  end

  def running?
    [start_time.present? && start_time < Time.now,
     end_time.present? && end_time > Time.now].all?
  end

  def creation_permissible?
    unless [keywords, start_time, end_time].map(&:present?).all?
      Rails.logger.info('Cannot create cohort unless metadata is present')
      return false
    end

    unless Time.now > end_time
      Rails.logger.info('Cannot create cohort until data collection is done')
      return false
    end

    true
  end

  private

  def add_index_name
    update_column(:index_name, IndexName.new("cc_#{self.id}").generate)
  end

  def es_client
    @es_client ||= Elasticsearch::Client.new
  end

  # This freezes the keywords as they existed at the time of the configuration,
  # to aid in debugging. It also allows for collaborators to query
  # CohortCollector directly for keywords rather than reaching through it to
  # SearchQuery.
  def initialize_keywords
    update_column(:keywords, search_queries.pluck(:keyword))
  end

  def services_available?
    # the [e] is to turn it into a regex, so that the grep command itself does
    # not show up in the ps results.
    `ps aux | grep [e]lasticsearch` != ''
  end
end
