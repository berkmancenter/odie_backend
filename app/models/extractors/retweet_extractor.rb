class RetweetExtractor < Extractor
  private

  def extract
    @tweets.map { |tweet| all_nested(:retweeted_status, tweet) }
           .flatten
           .map { |tweet| tweet.attrs[:full_text] }
           .each do |tweet|
             all_things[tweet] += 1
           end
  end
end
