class MentionExtractor < Extractor
  private

  def extract
    items_users = @tweets.map { |tweet| all_nested_with_user(:user_mentions, tweet) }
                         .flatten(1)

    items_users = items_users.map do |item|
      [item[:user_id]].product(item[:items])
    end

    # [0] is the user_id, [1] is the item
    items_users.flatten(1)
               .uniq { |user_and_item| [user_and_item[0], user_and_item[1].screen_name] }
               .map { |user_and_item| user_and_item[1].screen_name }
               .each do |mention|
                 @all_things[mention] += 1 unless mention.nil?
               end
  end
end
