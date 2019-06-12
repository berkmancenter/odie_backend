# == Schema Information
#
# Table name: data_configs
#
#  id         :bigint           not null, primary key
#  index_name :string
#  keywords   :string           is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

describe DataConfig do
  let(:phoenix) {
    MediaSource.create(
      description: 'alternative weekly known for arts coverage',
      name: 'Boston Phoenix',
      url: 'www.phoenix.com'
    )
  }
  let(:liberator) {
    MediaSource.create(
      description: 'abolitionist, feminist paper with influential readership',
      name: 'The Liberator',
      url: 'www.hellyeahgrimkésisters.org'
    )
  }

  it 'is created with the expected keywords' do
    dc = DataConfig.new(media_sources: [phoenix, liberator])
    dc.save
    expect(dc.keywords)
      .to contain_exactly('phoenix', 'hellyeahgrimkésisters')
  end

  # DataConfig caches keywords at creation to aid in debugging & historical
  # understanding. If it changed keywords when its media sources were edited,
  # we would be unable to track down certain types of bugs, and we would not
  # know what search had actually been performed to populate a given index.
  it 'does not change keywords when its underlying media sources are updated' do
    phoenix_dup = phoenix.dup
    phoenix_dup.save
    dc = DataConfig.new(media_sources: [phoenix])
    dc.save
    phoenix_dup.url = 'totally-different-url.com'
    phoenix_dup.save
    expect(dc.keywords).to eq ['phoenix']
  end

  # This can't be combined with the following test; somehow the expectation
  # interferes with the model creation and we end up with the wrong data.
  it 'manufactures data sets corresponding' do
    expect(DataSet).to receive(:create).twice.and_return(true)
    dc = DataConfig.new(media_sources: [phoenix, liberator])
    dc.save
    dc.manufacture_data_sets
  end

  it 'manufactures data sets corresponding to its media sources' do
    dc = DataConfig.new(media_sources: [phoenix, liberator])
    dc.save
    dc.manufacture_data_sets
    source_ids = DataSet.last(2).map { |ds| ds.media_source_id }
    expect(source_ids).to contain_exactly(phoenix.id, liberator.id)
  end
end
