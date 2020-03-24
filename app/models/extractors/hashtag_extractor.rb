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
    items_users = @tweets.map { |tweet| all_nested_with_user(:hashtags, tweet) }
                         .flatten(1)

    items_users = items_users.map do |item|
      [item[:user_id]].product(item[:items])
    end

    # [0] is the user_id, [1] is the item
    items_users.flatten(1)
               .uniq { |user_and_item| [user_and_item[0], user_and_item[1].text] }
               .map { |user_and_item| user_and_item[1] }
               .reject { |hashtag| hashtag.class == Twitter::NullObject }
               .map(&:text)
               .each do |hashtag|
                 @all_things[hashtag] += 1 unless hashtag.nil?
               end
  end
end
