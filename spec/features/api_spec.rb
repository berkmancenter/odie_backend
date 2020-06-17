require 'rails_helper'

feature 'API' do
  include Devise::Test::IntegrationHelpers

  before :each do
    login_as(create(:user))
  end

  context '/cohorts' do
    before :all do
      create_list(:cohort, 3)
    end

    after :all do
      Cohort.destroy_all
    end

    it 'returns a list of all cohorts' do
      visit cohorts_path
      expect(page.body).to eq(
        CohortSerializer.new(Cohort.all).serialized_json
      )
    end
  end

  context '/cohorts/:id' do
    let(:cohort) { create(:cohort) }

    it 'returns the expected attributes' do
      create(:data_set, cohort: cohort)

      visit cohort_path(id: cohort.id)
      expectation = {
        id: "#{cohort.id}",
        type: 'cohort',
        attributes: {
          description: 'Berkman Klein Center for Internet & Society',
          latest_data: DataSetSerializer.new(cohort.latest_data_set).serializable_hash
        }
      }

      expect(JSON.parse(page.body)['data'].to_json).to eq expectation.to_json
    end

    it 'handles cases where there are no attached data sets' do
      visit cohort_path(id: cohort.id)
      expect(latest_data_set(page)).to eq nil
    end

    it 'handles cases where there are multiple attached data sets' do
      create_list(:data_set, 2, cohort: cohort)
      visit cohort_path(id: cohort.id)

      expect(latest_data_set(page)['data']['id']).to eq DataSet.last.id.to_s
    end
  end

  context '/cohorts?ids[]=1&ids[]=2', elasticsearch: true do
    before :all do
      create_list(:cohort, 2)
      VCR.use_cassette('data set spec') do
        create(:data_set, cohort: Cohort.second_to_last).run_pipeline
        create(:data_set, cohort: Cohort.last).run_pipeline
      end
    end

    # Anything created in a before :all is outside of the transaction and needs
    # to be manually cleaned.
    after :all do
      TweetFetcher.destroy_all
      DataSet.destroy_all
      Cohort.destroy_all
      Retweet.destroy_all
    end

    it 'returns aggregated data' do
      visit cohorts_path(params: { ids: Cohort.pluck(:id) })
      json = JSON.parse(page.body)
      expect(json.keys).to include 'aggregates'
      check_aggregates json['aggregates'].symbolize_keys, DataSet.aggregate([DataSet.last.id, DataSet.second_to_last.id])
    end

    it 'aggregates from the most recent data set' do
      VCR.use_cassette('data set spec') do
        create(:data_set, cohort: Cohort.second_to_last).run_pipeline
        create(:data_set, cohort: Cohort.last).run_pipeline
      end

      visit cohorts_path(params: { ids: Cohort.pluck(:id) })
      json = JSON.parse(page.body)
      expect(json.keys).to include 'aggregates'
      check_aggregates json['aggregates'].symbolize_keys, DataSet.aggregate([DataSet.last.id, DataSet.second_to_last.id])
    end

    it 'only aggregates requested cohorts' do
      ids = Cohort.pluck(:id)
      expected = DataSet.aggregate([DataSet.last.id, DataSet.second_to_last.id])

      VCR.use_cassette('data set spec') do
        create(:data_set, cohort: create(:cohort)).run_pipeline
      end

      visit cohorts_path(params: { ids: ids })
      json = JSON.parse(page.body)
      expect(json.keys).to include 'aggregates'
      check_aggregates json['aggregates'].symbolize_keys, expected
    end
  end

  def latest_data_set(page)
    JSON.parse(page.body)['data']['attributes']['latest_data']
  end

  def check_aggregates(json_aggs_symbolized, data_sets_aggregated)
    json_aggs_symbolized[:top_retweets] = json_aggs_symbolized[:top_retweets].deep_transform_keys { |key| key.match(/\s/) ? key : key.to_sym }
    expect(json_aggs_symbolized[:hashtags]).to eq(data_sets_aggregated[:hashtags])
    expect(json_aggs_symbolized[:top_mentions]).to eq(data_sets_aggregated[:top_mentions])
    expect(json_aggs_symbolized[:top_sources]).to eq(data_sets_aggregated[:top_sources])
    expect(json_aggs_symbolized[:top_urls]).to eq(data_sets_aggregated[:top_urls])
    expect(json_aggs_symbolized[:top_words]).to eq(data_sets_aggregated[:top_words])
    expect(json_aggs_symbolized[:top_retweets]).to eq(data_sets_aggregated[:top_retweets])
  end
end
