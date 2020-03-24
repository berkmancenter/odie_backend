class UrlExtractor < Extractor
  private

  def extract
    # See https://developer.twitter.com/en/docs/tweets/data-dictionary/overview/entities-object.html#hashtags
    # Extract url objects
    items_users = @tweets.map { |tweet| all_nested_with_user(:urls, tweet) }
                         .flatten(1)

    items_users = items_users.map do |item|
      [item[:user_id]].product(item[:items])
    end

    # [0] is the user_id, [1] is the item
    items_users.flatten(1)
               .uniq { |user_and_item| [user_and_item[0], normalized_url(user_and_item[1])] }
               .map { |user_and_item| normalized_url(user_and_item[1]) }
               .select(&:present?)
               .each do |url| # update url counter
                 @all_things[url] += 1
               end
  end

  # The expanded_url is the most informative field, per Twitter developer docs.
  # We omit the querystring because these are generally tracking data for social
  # media campaigns, and will lead to spurious differences between URLs that
  # should probably be treated as identical. We omit scheme because there's no
  # reason to distinguish http and https versions of the same URL in this
  # context.
  def normalized_url(url_obj)
    Addressable::URI.parse(url_obj.expanded_url)
                    .omit(:query, :scheme)
                    .to_s
                    .delete_prefix('//')
  end
end
