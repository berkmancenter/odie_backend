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

  context '/cohorts?ids[]=1&ids[]=2' do
    before :all do
      create_list(:cohort, 2)
      create(:data_set, cohort: Cohort.second_to_last)
      create(:data_set, cohort: Cohort.last)
    end

    after :all do
      DataSet.destroy_all
      Cohort.destroy_all
    end

    it 'returns aggregated data' do
      visit cohorts_path(params: { ids: [Cohort.pluck(:id)] })
      json = JSON.parse(page.body)
      expect(json.keys).to include 'aggregates'
      expect(json['aggregates'].symbolize_keys).to eq(
        DataSet.aggregate([DataSet.last.id, DataSet.second_to_last.id])
      )
    end

    it 'aggregates from the most recent data set' do
      create(:data_set, cohort: Cohort.second_to_last)
      create(:data_set, cohort: Cohort.last)

      visit cohorts_path(params: { ids: [Cohort.pluck(:id)] })
      json = JSON.parse(page.body)
      expect(json.keys).to include 'aggregates'
      expect(json['aggregates'].symbolize_keys).to eq(
        DataSet.aggregate([DataSet.last.id, DataSet.second_to_last.id])
      )
    end
  end

  def latest_data_set(page)
    JSON.parse(page.body)['data']['attributes']['latest_data']
  end
end
