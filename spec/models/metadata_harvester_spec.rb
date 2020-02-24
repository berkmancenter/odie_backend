require 'rails_helper'

describe MetadataHarvester do
  let(:tweets) { [] }

  context 'returns the correct type of extractor for' do
    it 'hashtags' do
      assert (MetadataHarvester.new(:hashtags, tweets)).instance_of? HashtagExtractor
    end

    it 'urls' do
      assert (MetadataHarvester.new(:urls, tweets)).instance_of? UrlExtractor
    end

    it 'words' do
      assert (MetadataHarvester.new(:words, tweets)).instance_of? WordExtractor
    end

    it 'mentions' do
      assert (MetadataHarvester.new(:mentions, tweets)).instance_of? MentionExtractor
    end

    it 'sources' do
      assert (MetadataHarvester.new(:sources, tweets)).instance_of? SourceExtractor
    end

    it 'retweets' do
      assert (MetadataHarvester.new(:retweets, tweets)).instance_of? RetweetExtractor
    end
  end
end
