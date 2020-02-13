# frozen_string_literal: true

# == Schema Information
#
# Table name: data_sets
#
#  id             :bigint           not null, primary key
#  hashtags       :hstore
#  index_name     :string
#  num_retweets   :integer
#  num_tweets     :integer
#  num_users      :integer
#  top_mentions   :hstore
#  top_retweets   :hstore
#  top_sources    :hstore
#  top_urls       :hstore
#  top_words      :hstore
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  cohort_id      :bigint
#  data_config_id :bigint
#
# Indexes
#
#  index_data_sets_on_cohort_id       (cohort_id)
#  index_data_sets_on_data_config_id  (data_config_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#  fk_rails_...  (data_config_id => data_configs.id)
#

require 'rails_helper'

describe DataSet do
  let(:ds) { create(:data_set) }

  context 'index names' do
    it 'sets them on creation' do
      expect(ds.index_name).to be
    end

    it 'protects them against change' do
      orig_name = ds.index_name
      ds.index_name = 'brand-new-index-name'
      ds.save
      expect(ds.reload.index_name).to eq orig_name
    end

    context 'acceptable to elasticsearch' do
      it 'is lowercase' do
        expect(ds.index_name).to eq ds.index_name.downcase
      end

      it 'contains no forbidden characters' do
        expect(ds.index_name.split('') & '#\/*?"<>| ,:'.split('')).to eq []
      end

      it 'does not start with -, _, +, .' do
        expect(['-', '_', '+', '.'].include? ds.index_name.first).to be false
      end
    end
  end

  context 'during data ingestion' do
    it 'asks twitter for data on a user' do
      VCR.use_cassette('data set spec') do
        expect_any_instance_of(Twitter::REST::Client)
          .to receive(:user_timeline)
          .once
          .with(1, count: Rails.application.config.tweets_per_user,
                tweet_mode: 'extended')
        allow(ds).to receive(:index_exists?).and_return(true)
        ds.fetch_tweets(1)
      end
    end

    it 'creates an elasticsearch document for each tweet' do
      tweets = [
        { foo: 1 }, { bar: 2 }
      ]
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
      ds.store_data(tweets)
    end

    it 'fetches data on all cohort users' do
      VCR.use_cassette('data ingestion') do
        ds.cohort.twitter_ids.each do |id|
          expect(ds).to receive(:fetch_tweets).with(id)
        end
        expect(ds).to receive(:store_data)
                  .exactly(ds.cohort.twitter_ids.length)
                  .times
        ds.ingest_data
      end
    end
  end

  context 'data aggregation' do
    it 'sets aggregates appropriately' do
      VCR.use_cassette('data aggregation') do
        cohort = create(:cohort)
        ds_pipelined = DataSet.create(cohort: cohort)
        # Keep the data to a readable level so we can check the test suite
        # assertions.
        allow(Rails.application.config).to receive(:tweets_per_user)
                                       .and_return(10)

        ds_pipelined.run_pipeline

        expect(ds_pipelined.num_retweets).to eq 5
        expect(ds_pipelined.num_tweets).to eq 10
        expect(ds_pipelined.num_users).to eq 1
        expect(ds_pipelined.top_mentions).to eq ({
          "BKCHarvard"=>"5", "JessicaFjeld"=>"2", "evelyndouek"=>"2"
        })
        expect(ds_pipelined.top_retweets).to eq({})
        expect(ds_pipelined.top_sources).to eq({
          "bit.ly"=>"2", "medium.com"=>"2", "news.bloomberglaw.com"=>"2",
          "twitter.com"=>"2"
        })
        expect(ds_pipelined.top_words).to eq({
          "-"=>"2", "bkc"=>"2", "check"=>"2", "interns"=>"2", "looking"=>"2",
          "must"=>"2", "new"=>"2", "q&amp;a"=>"2", "👇"=>"2"
        })
        expect(ds_pipelined.top_urls).to eq({
          "news.bloomberglaw.com/ip-law/amazons-judging-of-ip-disputes-questioned-in-sellers-lawsuits"=>"2"
        })
      end
    end
  end
end
