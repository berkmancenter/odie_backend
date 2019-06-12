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

require 'rails_helper'

describe DataSet do
  let(:ms) do
    MediaSource.new(
      description: 'The first multi-page newspaper published in the Americas',
      name: 'Publick Occurrences Both Forreign and Domestick',
      url: 'https://www.publick-occurrences.com'
    )
  end
  let(:dc) do
    DataConfig.new(
      media_sources: [ms]
    )
  end
  let(:ds) { DataSet.create(media_source: ms, data_config: dc) }

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

  context 'data ingestion' do
    before { stub_request(:any, /twitter/) }

    it 'asks twitter for data on a user' do
      expect_any_instance_of(Twitter::REST::Client)
        .to receive(:user_timeline)
        .once.with(1, count: Rails.application.config.tweets_per_user)
      allow(ds).to receive(:index_exists?).and_return(true)
      ds.fetch_tweets(1)
    end

    def store_data(tweets)
      tweets.each do |tweet|
        es_client.create index: index_name, type: 'tweets', body: tweet.to_json
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
        .once.with(index: ds.index_name, type: 'tweets', body: tweets[0].to_json)
      expect_any_instance_of(Elasticsearch::API::Actions)
        .to receive(:create)
        .once.with(index: ds.index_name, type: 'tweets', body: tweets[1].to_json)
      ds.store_data(tweets)
    end
  end
end
