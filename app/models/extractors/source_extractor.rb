class SourceExtractor < Extractor
  private

  def extract
    @tweets.map { |tweet| all_nested_with_user(:urls, tweet) }
           .flatten
           .each do |item_user|
             @working_space[host(item_user[:item])] << item_user[:user_id]
           end
  end

  def host(url_obj)
    Addressable::URI.parse(url_obj.expanded_url).host
  end
end
