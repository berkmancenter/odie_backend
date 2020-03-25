class UrlExtractor < Extractor
  private

  def extract
    @tweets.map { |tweet| all_nested_with_user(:urls, tweet) }
           .flatten
           .each do |item_user|
             @working_space[normalized_url(item_user[:item])] << item_user[:user_id]
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
