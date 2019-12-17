require 'rails_helper'

feature 'Media Sources' do
  include Devise::Test::IntegrationHelpers
  let(:admin_user) { build(:user, :admin) }
  let(:api_user) { build(:user) }

  context '/media_sources' do
    before do
      3.times do
        create(:media_source, :active)
      end
    end

    it 'resolves' do
      visit media_sources_path
      expect(page.status_code).to eq 200
    end

    it 'returns a list of all active media sources' do
      visit media_sources_path
      expect(page.body).to eq(
        MediaSourceSerializer.new(MediaSource.all).serialized_json
      )
    end

    it 'does not return inactive media sources' do
      create(:media_source, :inactive)

      visit media_sources_path
      expect(page.body).to eq(
        MediaSourceSerializer.new(
          MediaSource.where(active: true)
        ).serialized_json
      )
    end
  end

  context '/media_sources/:id' do
    let(:ms) { create(:media_source, :evening_traveler) }

    it 'resolves' do
      visit media_source_path(id: ms.id)
      expect(page.status_code).to eq 200
    end

    it 'returns the expected attributes' do
      dc = DataConfig.new(media_sources: [ms])
      ds = DataSet.create(media_source: ms, data_config: dc)

      visit media_source_path(id: ms.id)
      expectation = {
        id: "#{ms.id}",
        type: 'media_source',
        attributes: {
          description: 'The Boston Evening Traveler was a daily paper designed ' \
                       'to be read around the family fireplace and covering a ' \
                       'variety of topics. It opposed the expansion of ' \
                       'slavery. It was absorbed by the Herald in 1912.',
          name: 'Boston Evening Traveler',
          url: 'www.bostonherald.com',
          latest_data: DataSetSerializer.new(ds).serializable_hash
        }
      }

      expect(JSON.parse(page.body)['data'].to_json).to eq expectation.to_json
    end

    it 'handles cases where there are no attached data sets' do
      ms.data_sets.delete_all
      visit media_source_path(id: ms.id)
      expect(latest_dataset(page)).to eq nil
    end

    it 'handles cases where there are multiple attached data sets' do
      dc = DataConfig.new(media_sources: [ms])
      ds1 = DataSet.create(media_source: ms, data_config: dc)
      ds2 = DataSet.create(media_source: ms, data_config: dc)
      visit media_source_path(id: ms.id)
      expect(latest_dataset(page)[:data][:id]).to eq ds2.id.to_s
    end
  end

  context '/media_sources/aggregate' do
    let(:ms1) { create(:media_source, :evening_traveler) }
    let(:ms2) { create(:media_source, :spy) }

    let(:dc) do
      DataConfig.new(
        media_sources: [ms1, ms2]
      )
    end
    let(:ds1) { DataSet.create(media_source: ms1, data_config: dc) }
    let(:ds2) { DataSet.create(media_source: ms2, data_config: dc) }

    it 'resolves' do
      visit media_source_aggregate_path(format: :json)
      expect(page.status_code).to eq 200
    end

    it 'returns the expected data with one object' do
      [ms1, ds1] # force these to exist in scope
      visit media_source_aggregate_path({ids: [ms1.id], format: :json})
      results = JSON.parse(page.body)
      expect(results['data'].length).to eq 1
      expect(json_dataset_from(results, ms1.id)).to eq(
        dataset_serialization(ds1)
      )
      expect(results['errors']).to be nil
    end

    it 'returns the expected data with multiple objects' do
      [ms1, ms2, ds1, ds2]
      visit media_source_aggregate_path({ids: [ms1.id, ms2.id], format: :json})
      results = JSON.parse(page.body)
      expect(results['data'].length).to eq 2
      expect(json_dataset_from(results, ms1.id)).to include(
        dataset_serialization(ds1)
      )
      expect(json_dataset_from(results, ms2.id)).to include(
        dataset_serialization(ds2)
      )
      expect(results['errors']).to be nil
    end

    it 'handles nonexistent IDs' do
      [ms1, ms2, ds1, ds2]
      bad_id = ms2.id
      ms2.delete
      visit media_source_aggregate_path({ids: [ms1.id, bad_id], format: :json})
      results = JSON.parse(page.body)
      expect(results['data'].length).to eq 1
      expect(results['data'].to_json).to include(
        dataset_serialization(ds1)
      )
      expect(results['errors']).to eq 'One or more specified MediaSources do not exist'
    end

    it 'handles bogus IDs' do
      [ms1, ds1]
      visit media_source_aggregate_path({ids: [ms1.id, 'cows'], format: :json})
      results = JSON.parse(page.body)
      expect(results['data'].length).to eq 1
      expect(results['data'].to_json).to include(
        dataset_serialization(ds1)
      )
      expect(results['errors']).to eq 'One or more specified MediaSources do not exist'
    end

    it 'handles media sources without data sets' do
      ms3 = MediaSource.create(
        description: 'A heavily political weekly paper constantly on the ' \
                     'verge of being suppressed by the Royalist government.',
        name: 'Massachusetts Spy',
        url: 'https://www.mass.spy')
      visit media_source_aggregate_path({ids: [ms3.id], format: :json})
      results = JSON.parse(page.body)
      expect(json_dataset_from(results, ms3.id)).to eq nil
    end
  end

  def json_dataset_from(results, id)
    raw = results['data'].select { |item| item['id'] == id.to_s }
          .first['attributes']['latest_data']

    case raw
    when nil
      nil
    else
      raw['data'].to_json
    end
  end

  def dataset_serialization(dataset)
    DataSetSerializer.new(dataset).serializable_hash[:data].to_json
  end

  def latest_dataset(result)
    JSON.parse(
      result.body, symbolize_names: true
    )[:data][:attributes][:latest_data]
  end
end
