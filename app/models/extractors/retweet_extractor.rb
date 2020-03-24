class RetweetExtractor < Extractor
  private

  def extract
    @tweets.map { |tweet| all_nested(:retweeted_status, tweet) }
           .flatten
           .map do |tweet|
             {
               text: tweet.attrs[:full_text],
               link: tweet.uri.to_s
             }
           end
           .each do |tweet|
             if @all_things[tweet[:text]].is_a?(Hash)
               @all_things[tweet[:text]][:count] += 1
             else
               @all_things[tweet[:text]] = {
                 count: 1,
                 link: tweet[:link]
               }
             end
           end
  end

  def collate
    # Only report the top N ranks (including ties), and don't report anything
    # below the threshold.
    min_count = @all_things.map { |_k, v| v[:count] }.sort.last(TOP_N)[0]
    @all_things.reject { |_k, v| v[:count] < [min_count, THRESHOLD].max }
  end
end
