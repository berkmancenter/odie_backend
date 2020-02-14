class HashtagExtractor < Extractor
  private

  def extract
    # See https://developer.twitter.com/en/docs/tweets/data-dictionary/overview/entities-object.html#hashtags .
    # Sadly, a lot going on here:
    # - extract hashtags from tweet object and its retweeted or quoted tweets
    # - when there isn't a RT/quote tweet, we end up with a Twitter::NullObject
    #   rather than nil, so we need to reject those rather than using .compact;
    #   further, hashtag objects don't respond to is_instance?
    # - once our list contains only hashtag objects, get their text
    # - then count how many times we've seen each text
    @tweets.map { |tweet| all_nested(:hashtags, tweet) }
           .flatten
           .reject { |tweet| tweet.class == Twitter::NullObject }
           .map { |hashtag| hashtag.text }
           .each do |hashtag|
             @all_things[hashtag] += 1
           end
    end
end
