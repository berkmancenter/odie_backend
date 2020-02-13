class UrlExtractor < Extractor
  private

  def extract
    # See https://developer.twitter.com/en/docs/tweets/data-dictionary/overview/entities-object.html#hashtags .
    @tweets.map { |tweet| all_nested(:urls, tweet) }     # extract url objects
           .flatten
           .map { |url_obj| normalized_url(url_obj) }  # extract url text
           .each do |url|                              # update url counter
             all_things[url] += 1
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
