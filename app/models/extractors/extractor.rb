# Shared logic for extracting aggregated metadata from tweets. This performs
# bookkeeping functions and is not intended to be invoked directly.
# The `harvest` method returns a hash of the top THRESHHOLD most common
# elements of the given data type within the given set of tweets.
# Subclasses should define an `extract` method which has the type-specific logic
# for finding their metadata type (user mentions, hashtags, etc.)
# This class provides `all_nested` as a utility for its subclasses -- it pulls
# out all objects of the given type from the tweet and its retweeted or
# quoted tweets (since the top-level tweet object does not contain everything
# visible to users who are reading an actual timeline).
class Extractor
  THRESHHOLD = 2

  def initialize(tweets)
    @tweets = tweets.flatten
  end

  # Subclasses should define as the logic of extracting an object may be
  # type-specific.
  def extract; end

  def all_things
    @all_things ||= Hash.new 0
  end

  # Return every key/value pair that occurs above THRESHHOLD number of times.
  # (the hash is presumed to be of keys & integers representing the frequency
  # of that key in the dataset).
  # If there isn't anything above the THRESHHOLD, just return everything.
  def collate
    candidates = all_things.values.sort[THRESHHOLD]
    if candidates
      all_things.reject { |k, v| v < THRESHHOLD }
    else
      all_things
    end
  end

  # Entity objects may be contained in the tweet, its retweeted tweet, or its
  # quoted tweet.
  def all_nested(obj_type, tweet)
    [tweet.send(obj_type),
     tweet.retweeted_status&.send(obj_type),
     tweet.retweeted_status&.quoted_status&.send(obj_type),
     tweet.quoted_status&.send(obj_type)]
  end

  def harvest
    extract
    collate
  end
end
