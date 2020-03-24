class SourceExtractor < Extractor
  private

  def extract
    items_users = @tweets.map { |tweet| all_nested_with_user(:urls, tweet) }
                         .flatten(1)

    items_users = items_users.map do |item|
      [item[:user_id]].product(item[:items])
    end

    # [0] is the user_id, [1] is the item
    items_users.flatten(1)
               .uniq { |user_and_item| [user_and_item[0], host(user_and_item[1])] }
               .map { |user_and_item| user_and_item[1] }
               .map { |url_obj| host(url_obj) }
               .reject(&:nil?)
               .each do |url|
                 @all_things[url] += 1 unless url.nil?
               end
  end

  def host(url_obj)
    Addressable::URI.parse(url_obj.expanded_url).host
  end
end
