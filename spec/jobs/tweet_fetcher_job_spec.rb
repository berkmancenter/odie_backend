require 'rails_helper'

describe TweetFetchingJob do
  let(:ds) { build(:data_set) }

  # rspec overall needs to execute jobs immediately so that data-collecting
  # behavior happens, but for the duration of this test suite we need to use
  # the default job execution behavior, so that we can test it.
  before(:all) { Delayed::Worker.delay_jobs = true }
  after(:all)  { Delayed::Worker.delay_jobs = false }

  context 'during data ingestion', elasticsearch: true do
    it 'asks twitter for data on a user' do
      VCR.use_cassette('data set spec') do
        expect_any_instance_of(Twitter::REST::Client)
          .to receive(:user_timeline)
          .once
          .with(1, count: Rails.application.config.tweets_per_user,
                tweet_mode: 'extended')

        allow_any_instance_of(TweetFetchingJob).to receive(:store_data)
        allow(ds).to receive(:finalize_when_ready)

        TweetFetchingJob.perform_now(ds, 1)
      end
    end

    it 'creates an elasticsearch document for each tweet' do
      tweets = [
        { foo: 1 }, { bar: 2 }
      ]
      allow_any_instance_of(TweetFetchingJob).to receive(:fetch_tweets)
                                             .and_return(tweets)
      verify_index

      # Why not expect_any_instance_of(Elasticsearch::Client)? Because the
      # create action is provided by a mixin, so although it's present on all
      # instances, the the test suite can't find it on the class, and therefore
      # can't mock it.
      expect_any_instance_of(Elasticsearch::API::Actions)
        .to receive(:create)
        .once.with(index: ds.index_name, type: '_doc', body: tweets[0].to_json)
      expect_any_instance_of(Elasticsearch::API::Actions)
        .to receive(:create)
        .once.with(index: ds.index_name, type: '_doc', body: tweets[1].to_json)

      TweetFetchingJob.perform_now(ds, 1)
    end

    it 'handles unauthorized accounts' do
      allow_any_instance_of(TweetFetchingJob).to receive(:fetch_tweets)
        .and_raise Twitter::Error::Unauthorized
      verify_index

      TweetFetchingJob.perform_now(ds, 1)
      TweetFetchingJob.perform_now(ds, 2)

      expect(ds.unauthorized).to match_array ['1', '2']
    end
  end

  context 'backoff' do
    it 'is none when is nothing else in the queue' do
      mock_count(1)

      expect(TweetFetchingJob.backoff).to eq 0
    end

    it 'is none when there is not much in the queue' do
      mock_count(Rails.configuration.rate_limit_limit * 0.25)

      expect(TweetFetchingJob.backoff).to eq 0
    end

    it 'is small when the queue is mid-sized' do
      # We cross 0 when the queue is half of 95% of the limit size (95% rather
      # than 100% for a safety margin). So if we are just one item above that
      # limit, we expect a nonzero but small backoff time.
      mock_count(Rails.configuration.rate_limit_limit * 0.95 * 0.5 + 1)

      expect(TweetFetchingJob.backoff).to be > 0
      expect(TweetFetchingJob.backoff).to be < 60  # 1.minute
    end

    it 'is long when there are many things in queue' do
      mock_count(Rails.configuration.rate_limit_limit * 1.05)

      expect(TweetFetchingJob.backoff).to be > (Rails.configuration.rate_limit_window * 60)
    end

    it 'is re-enqueued upon receiving TooManyRequests' do
      ds.save
      allow_any_instance_of(Twitter::REST::Client)
        .to receive(:user_timeline)
        .and_raise Twitter::Error::TooManyRequests

      TweetFetchingJob.perform_now(ds, 1)

      expect(Delayed::Job.all.count).to eq 1
    end

    def mock_count(num)
      allow(TweetFetchingJob).to receive(:enqueued).and_return(num)
    end
  end

  context 'updating aggregates of parent data set', elasticsearch: true do
    it 'happens when all jobs are performed' do
      ds.cohort.twitter_ids = [1]
      ds.cohort.save
      # Mock out all the actions that integrate with outside things -- we're
      # just ensuring that the message gets sent.
      allow_any_instance_of(TweetFetchingJob).to receive(:fetch_tweets)
      allow_any_instance_of(TweetFetchingJob).to receive(:store_data)
      allow(ds).to receive(:update_aggregates)

      TweetFetchingJob.perform_now(ds, 1)

      expect(ds).to have_received(:update_aggregates)
    end

    it 'does not happen before all jobs are performed' do
      ds.cohort.twitter_ids = [1, 2]
      ds.cohort.save
      allow_any_instance_of(TweetFetchingJob).to receive(:fetch_tweets)
      allow_any_instance_of(TweetFetchingJob).to receive(:store_data)
      allow(ds).to receive(:update_aggregates)

      TweetFetchingJob.perform_now(ds, 1)

      expect(ds).not_to have_received(:update_aggregates)
    end

    it 'happens when there is an un-retry-able exception' do
      ds.cohort.twitter_ids = [1]
      ds.cohort.save
      # Mock out all the actions that integrate with outside things -- we're
      # just ensuring that the message gets sent.
      allow_any_instance_of(TweetFetchingJob).to receive(:fetch_tweets)
        .and_raise Twitter::Error::Unauthorized
      allow(ds).to receive(:update_aggregates)

      TweetFetchingJob.perform_now(ds, 1)

      expect(ds).to have_received(:update_aggregates)
    end

    it 'does not happen when there is an exception meriting retry' do
      ds.save
      ds.cohort.twitter_ids = [1]
      ds.cohort.save
      # Mock out all the actions that integrate with outside things -- we're
      # just ensuring that the message gets sent.
      allow_any_instance_of(TweetFetchingJob).to receive(:fetch_tweets)
        .and_raise Twitter::Error::TooManyRequests
      allow(ds).to receive(:update_aggregates)

      TweetFetchingJob.perform_now(ds, 1)

      expect(ds).not_to have_received(:update_aggregates)
    end
  end

  def verify_index
    ds.save
    ds.send(:verify_index)
  end
end
