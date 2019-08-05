require 'rails_helper'

feature 'Media Sources' do
  include Devise::Test::IntegrationHelpers
  let(:admin_user) { User.new(email: 'admin@exmaple.com', admin: true) }
  let(:api_user) { User.new(email: 'api@exmaple.com', admin: false) }

  context '/media_sources' do
    before do
      3.times do
        MediaSource.create(
          name: 'Editorial Humor',
          description: 'Political cartoons galore',
          url: 'edhumor.com',
          active: true
        )
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
      MediaSource.create(
        name: 'Bofton Weekly Poft-Boy',
        description: 'Published by Authority (!)',
        url: 'ellis.huske.com',
        active: false
      )
      visit media_sources_path
      expect(page.body).to eq(
        MediaSourceSerializer.new(
          MediaSource.where(active: true)
        ).serialized_json
      )
    end
  end

  context '/media_sources/:id' do
    let(:ms) {
      MediaSource.create(
        description: 'The Boston Evening Traveler was a daily paper designed ' \
                     'to be read around the family fireplace and covering a ' \
                     'variety of topics. It opposed the expansion of ' \
                     'slavery. It was absorbed by the Herald in 1912.',
        name: 'Boston Evening Traveler',
        url: 'https://www.bostonherald.com')
    }

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
        type: 'media_sources',
        attributes: {
          description: 'The Boston Evening Traveler was a daily paper designed ' \
                       'to be read around the family fireplace and covering a ' \
                       'variety of topics. It opposed the expansion of ' \
                       'slavery. It was absorbed by the Herald in 1912.',
          name: 'Boston Evening Traveler',
          url: 'www.bostonherald.com',
          latest_index: "#{ds.index_name}"
        }
      }

      # We need to symbolize the keys, included in the nested hash, to prevent
      # trivial comparison failures.
      expect(symbolize(page.body)).to eq expectation
    end

    it 'handles cases where there are no attached data sets' do

      ms.data_sets.delete_all
      visit media_source_path(id: ms.id)
      expect(latest_index(page)).to eq nil
    end

    it 'handles cases where there are multiple attached data sets' do
      dc = DataConfig.new(media_sources: [ms])
      ds1 = DataSet.create(media_source: ms, data_config: dc)
      ds2 = DataSet.create(media_source: ms, data_config: dc)
      visit media_source_path(id: ms.id)
      expect(latest_index(page)).to eq ds2.index_name
    end
  end

  def symbolize(hsh)
    result = JSON.parse(hsh)['data'].symbolize_keys
    result[:attributes] = result[:attributes].symbolize_keys
    result
  end

  def latest_index(result)
    symbolize(result.body)[:attributes][:latest_index]
  end
end
