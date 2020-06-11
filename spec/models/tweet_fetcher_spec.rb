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

require 'rails_helper'

describe TweetFetcher do
  let(:tf) { create(:tweet_fetcher, user_id: 1) }

  context 'during data ingestion', elasticsearch: true do
    it 'asks twitter for data on a user' do
      VCR.use_cassette('data set spec') do
        expect_any_instance_of(Twitter::REST::Client)
          .to receive(:user_timeline)
          .once
          .with(1, count: Rails.application.config.tweets_per_user,
                tweet_mode: 'extended')

        allow(tf).to receive(:store_data)
        allow(tf.data_set).to receive(:finish_when_ready)

        tf.ingest
      end
    end

    it 'creates an elasticsearch document for each tweet' do
      tweets = [
        { foo: 1 }, { bar: 2 }
      ]
      allow(tf).to receive(:fetch_tweets).and_return(tweets)
      tf.data_set.send(:verify_index)

      # Why not expect_any_instance_of(Elasticsearch::Client)? Because the
      # create action is provided by a mixin, so although it's present on all
      # instances, the the test suite can't find it on the class, and therefore
      # can't mock it.
      expect_any_instance_of(Elasticsearch::API::Actions)
        .to receive(:create)
        .once.with(index: tf.data_set.index_name, type: '_doc', body: tweets[0].to_json)
      expect_any_instance_of(Elasticsearch::API::Actions)
        .to receive(:create)
        .once.with(index: tf.data_set.index_name, type: '_doc', body: tweets[1].to_json)

      tf.ingest
    end

    it 'handles unauthorized accounts' do
      tf2 = create(:tweet_fetcher, user_id: 2, data_set: tf.data_set)
      allow(tf).to receive(:fetch_tweets)
               .and_raise Twitter::Error::Unauthorized
      allow(tf2).to receive(:fetch_tweets)
              .and_raise Twitter::Error::Unauthorized

      tf.ingest
      tf2.ingest

      expect(tf.data_set.unauthorized).to match_array [tf.user_id, tf2.user_id]
    end
  end
end
