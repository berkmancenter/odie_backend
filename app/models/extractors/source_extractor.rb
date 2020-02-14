class SourceExtractor < Extractor
  private

  def extract
    @tweets.map { |tweet| all_nested(:urls, tweet) }
           .flatten
           .map { |url_obj| host(url_obj) }
           .each do |url|
             @all_things[url] += 1
           end
  end

  def host(url_obj)
    Addressable::URI.parse(url_obj.expanded_url).host
  end
end
