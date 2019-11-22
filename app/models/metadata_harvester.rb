class MetadataHarvester
  OPTIONS = {
    hashtags: HashtagExtractor,
    urls: UrlExtractor,
    words: WordExtractor
  }

  def self.new(harvester_type, tweets)
    self::OPTIONS[harvester_type].new(tweets)
  end
end
