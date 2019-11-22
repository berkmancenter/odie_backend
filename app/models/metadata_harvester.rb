class MetadataHarvester
  OPTIONS = {
    hashtags: HashtagExtractor,
    urls: UrlExtractor,
    words: WordExtractor,
    mentions: MentionExtractor
  }

  def self.new(harvester_type, tweets)
    self::OPTIONS[harvester_type].new(tweets)
  end
end
