# == Schema Information
#
# Table name: search_queries
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

describe SearchQuery do
  let(:query_brief) { build(:search_query, url: 'washingtonpost.com') }
  let(:query) { build(:search_query, url: 'https://www.washingtonpost.com') }
  let(:query_long) {
    build(:search_query, url: 'https://www.washingtonpost.com/more_stuff?oh=yeah')
  }

  context 'URL validation' do
    it 'rejects invalid URLs' do
      bad_url = 'www.$[specialcharacters].com'
      expect { URI.parse(bad_url) }.to raise_error(URI::InvalidURIError)
      query = build(:search_query, url: bad_url)
      expect(query).not_to be_valid
    end

    it 'accepts urls with protocol + host' do
      expect(query).to be_valid
    end

    it 'accepts urls with just host' do
      expect(query_brief).to be_valid
    end

    it 'accepts urls with protocol + host + more stuff' do
      expect(query_long).to be_valid
    end
  end

  context 'keyword setting' do
    it 'is correct for urls with protocol + host' do
      query.save
      expect(query.keyword).to eq 'washingtonpost'
    end

    it 'is correct for urls with just host' do
      query_brief.save
      expect(query_brief.keyword).to eq 'washingtonpost'
    end

    it 'is correct for urls with protocol + host + more stuff' do
      query_long.save
      expect(query_long.keyword).to eq 'washingtonpost'
    end

    it 'is correct for urls with two-part TLDs' do
      foo = SearchQuery.create(
        description: 'Google, but elsewhere',
        name: 'google',
        url: 'https://www.google.co.uk'
      )
      expect(foo.keyword).to eq 'google'
    end

    it 'is correct for urls with weird TLDs' do
      foo = SearchQuery.create(
        description: 'the good part of the internet',
        name: 'tilde',
        url: 'https://tilde.club'
      )
      expect(foo.keyword).to eq 'tilde'
    end
  end
end
