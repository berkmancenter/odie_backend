# Shared logic for extracting aggregated metadata from tweets. This performs
# bookkeeping functions and is not intended to be invoked directly.
# The `harvest` method returns a hash of the top THRESHOLD most common
# elements of the given data type within the given set of tweets.
# Subclasses should define an `extract` method which has the type-specific logic
# for finding their metadata type (user mentions, hashtags, etc.)
# This class provides `all_nested` as a utility for its subclasses -- it pulls
# out all objects of the given type from the tweet and its retweeted or
# quoted tweets (since the top-level tweet object does not contain everything
# visible to users who are reading an actual timeline).
class Extractor
  THRESHOLD = ENV['EXTRACTOR_THRESHOLD'] ? ENV['EXTRACTOR_THRESHOLD'].to_i : 5
  TOP_N  = ENV['EXTRACTOR_TOP_N'] ? ENV['EXTRACTOR_TOP_N'].to_i : 5

  def initialize(tweets)
    @tweets = tweets.flatten
    @all_things = Hash.new 0
  end

  # Subclasses should define as the logic of extracting an object may be
  # type-specific.
  def extract; end

  def collate
    # Only report the top N ranks (including ties), and don't report anything
    # below the threshold.
    min_count = @all_things.values.sort.last(TOP_N)[0]
    @all_things.reject { |k, v| v < [min_count, THRESHOLD].max }
  end

  def harvest
    extract
    collate
  end

  private

  # Entity objects may be contained in the tweet, its retweeted tweet, or its
  # quoted tweet.
  def all_nested(obj_type, tweet)
    [tweet.send(obj_type),
     tweet.retweeted_status&.send(obj_type),
     tweet.retweeted_status&.quoted_status&.send(obj_type),
     tweet.quoted_status&.send(obj_type)]
  end
end
