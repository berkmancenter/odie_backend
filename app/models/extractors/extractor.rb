class Extractor
  def initialize(tweets)
    @tweets = tweets.flatten
  end

  # Subclasses should define as the logic of extracting an object may be
  # type-specific.
  def extract; end

  def all_things
    @all_things ||= Hash.new 0
  end

  # Return every key/value pair that is at least tied for 5th in popularity
  # (the hash is presumed to be of keys & integers representing the frequency
  # of that key in the dataset).
  # If there isn't a fifth place, just return everything.
  def collate
    threshhold = all_things.values.sort[-5]
    if threshhold
      all_things.reject { |k, v| v < threshhold }
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
