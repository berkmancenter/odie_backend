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
  it 'accepts urls with protocol + host' do
    foo = MediaSource.new(
      description: 'Democracy Dies in Darkness',
      name: 'WaPo',
      url: 'https://www.washingtonpost.com'
    )
    assert foo.valid?
  end

  it 'accepts urls with just host' do
    foo = MediaSource.new(
      description: 'Democracy Dies in Darkness',
      name: 'WaPo',
      url: 'www.washingtonpost.com'
    )
    assert foo.valid?
  end

  it 'accepts urls with protocol + host + more stuff' do
    foo = MediaSource.new(
      description: 'Democracy Dies in Darkness',
      name: 'WaPo',
      url: 'https://www.washingtonpost.com/more_stuff?oh=yeah'
    )
    assert foo.valid?
  end

  it 'correctly sets keywords for urls with protocol + host' do
    foo = MediaSource.new(
      description: 'Democracy Dies in Darkness',
      name: 'WaPo',
      url: 'https://www.washingtonpost.com'
    )
    foo.save
    assert foo.keyword == 'washingtonpost'
  end

  it 'correctly sets keywords for urls with just host' do
    foo = MediaSource.new(
      description: 'Democracy Dies in Darkness',
      name: 'WaPo',
      url: 'www.washingtonpost.com'
    )
    foo.save
    assert foo.keyword == 'washingtonpost'
  end

  it 'correctly sets keywords for urls with protocol + host + more stuff' do
    foo = MediaSource.new(
      description: 'Democracy Dies in Darkness',
      name: 'WaPo',
      url: 'https://www.washingtonpost.com/more_stuff?oh=yeah'
    )
    foo.save
    assert foo.keyword == 'washingtonpost'
  end

  it 'correctly sets keywords for urls with two-part TLDs' do
    foo = MediaSource.new(
      description: 'Google, but elsewhere',
      name: 'google',
      url: 'https://www.google.co.uk'
    )
    foo.save
    assert foo.keyword == 'google'
  end

  it 'correctly sets keywords for urls with weird TLDs' do
    foo = MediaSource.new(
      description: 'the good part of the internet',
      name: 'tilde',
      url: 'https://tilde.club'
    )
    foo.save
    assert foo.keyword == 'tilde'
  end
end
