# == Schema Information
#
# Table name: media_sources
#
#  id          :bigint           not null, primary key
#  active      :boolean
#  description :text
#  keyword     :string
#  name        :string
#  url         :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

describe MediaSource do
  let(:source_brief) { build(:media_source, url: 'www.washingtonpost.com') }
  let(:source) { build(:media_source, url: 'https://www.washingtonpost.com') }
  let(:source_long) {
    build(:media_source, url: 'https://www.washingtonpost.com/more_stuff?oh=yeah')
  }

  it 'accepts urls with protocol + host' do
    expect(source.valid?).to be true
  end

  it 'accepts urls with just host' do
    expect(source_brief.valid?).to be true
  end

  it 'accepts urls with protocol + host + more stuff' do
    expect(source_long.valid?).to be true
  end

  it 'correctly sets keywords for urls with protocol + host' do
    saveable = source.dup
    saveable.save
    expect(saveable.keyword).to eq 'washingtonpost'
  end

  it 'correctly sets keywords for urls with just host' do
    saveable = source_brief.dup
    saveable.save
    expect(saveable.keyword).to eq 'washingtonpost'
  end

  it 'correctly sets keywords for urls with protocol + host + more stuff' do
    saveable = source_long.dup
    saveable.save
    expect(saveable.keyword).to eq 'washingtonpost'
  end

  it 'correctly sets keywords for urls with two-part TLDs' do
    foo = MediaSource.new(
      description: 'Google, but elsewhere',
      name: 'google',
      url: 'https://www.google.co.uk'
    )
    foo.save
    expect(foo.keyword).to eq 'google'
  end

  it 'correctly sets keywords for urls with weird TLDs' do
    foo = MediaSource.new(
      description: 'the good part of the internet',
      name: 'tilde',
      url: 'https://tilde.club'
    )
    foo.save
    expect(foo.keyword).to eq 'tilde'
  end

  it 'provides the most recent data set' do
    dc = DataConfig.new(media_sources: [source])
    ds1 = DataSet.create(media_source: source, data_config: dc)
    ds2 = DataSet.create(media_source: source, data_config: dc)

    expect(source.latest_data).to eq ds2
  end
end
