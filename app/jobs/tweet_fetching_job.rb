class TweetFetchingJob < ApplicationJob
  queue_as :default

  # These exceptions indicate that retry will be unsuccessful, so we should
  # tell the parent DataSet that the user id has been fully processed.
  rescue_from(Twitter::Error::Unauthorized,
              Twitter::Error::BadRequest,
              Twitter::Error::Forbidden,
              Twitter::Error::NotFound,
              Twitter::Error::NotAcceptable,
              Twitter::Error::RequestEntityTooLarge,
              Twitter::Error::UnprocessableEntity) do |exception|
    do_completion_bookkeeping(false)
  end

  # This exception is retryable, but we should pause ALL jobs until after the
  # rate limiting window resets.
  rescue_from(Twitter::Error::TooManyRequests) do |exception|
    # Stop execution of jobs; restart it after the rate limiting window has
    # elapsed.
    stop_cmd = "RAILS_ENV=#{Rails.env} #{Rails.root}/bin/delayed_job stop"
    start_cmd = "RAILS_ENV=#{Rails.env} #{Rails.configuration.delayed_job_command} | at now + #{Rails.configuration.rate_limit_window} minutes"

    system(stop_cmd)
    system(start_cmd)

    TweetFetchingJob.perform_later(@data_set, @user_id)
  end

  # These exceptions indicate that the job may succeed if tried again.
  rescue_from(Twitter::Error::InternalServerError,
              Twitter::Error::BadGateway,
              Twitter::Error::ServiceUnavailable,
              Twitter::Error::GatewayTimeout) do |exception|
    TweetFetchingJob.set(wait: TweetFetchingJob.backoff)
                    .perform_later(@data_set, @user_id)
  end

  def perform(data_set, user_id)
    return if data_set.processed.include? user_id

    @data_set = data_set
    @user_id = user_id

    store_data(fetch_tweets)

    do_completion_bookkeeping
  end

  def reschedule_at(current_time, attempts)
    current_time + TweetFetchingJob.backoff
  end

  private

  def do_completion_bookkeeping(successful=true)
    @data_set.unauthorized << @user_id unless successful
    @data_set.processed << @user_id
    @data_set.save
    @data_set.finalize_when_ready
  end

  def fetch_tweets
    twitter_client.user_timeline(
      @user_id.to_i,
      count: Rails.application.config.tweets_per_user,
      tweet_mode: 'extended'
    )
  end

  def store_data(tweets)
    tweets.each do |tweet|
      es_client.create index: @data_set.index_name,
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

  def self.backoff
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
    [2*window - (2.0**(-2*enqueued/limit))*4*window, 0].max
  end

  # Separated into a function to make it easy to stub in testing.
  # Oddly, ActiveJob does not make it easy to find this number.
  def self.enqueued
    Delayed::Job.count
  end
end
