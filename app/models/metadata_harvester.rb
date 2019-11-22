# A factory which returns the correct extractor for the given data type,
# initialized with the tweet set.
class MetadataHarvester
  OPTIONS = {
    hashtags: HashtagExtractor,
    urls: UrlExtractor,
    words: WordExtractor,
    mentions: MentionExtractor,
    sources: SourceHarvester
  }

  def self.new(harvester_type, tweets)
    self::OPTIONS[harvester_type].new(tweets)
  end
end
