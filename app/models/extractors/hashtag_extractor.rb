class HashtagExtractor < Extractor
  private

  def extract
    # See https://developer.twitter.com/en/docs/tweets/data-dictionary/overview/entities-object.html#hashtags .
    # Sadly, a lot going on here:
    # - extract hashtags from tweet object and its retweeted or quoted tweets
    # - reject everything now empty (due to not having hashtags)
    # - when there isn't a RT/quote tweet, we may end up with a Twitter::NullObject
    #   rather than nil, so we need to reject those too;
    #   further, hashtag objects don't respond to is_instance?
    # - once our list contains only hashtag objects, get their text
    # - and keep track of which users have used each text

    @tweets.map { |tweet| all_nested_with_user(:hashtags, tweet) }
           .flatten
           .reject { |item_user| item_user[:item].class == Twitter::NullObject }
           .each do |item_user|
             @working_space[item_user[:item].text] << item_user[:user_id]
           end
  end
end
