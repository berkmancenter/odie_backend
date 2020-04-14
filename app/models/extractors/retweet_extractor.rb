class RetweetExtractor < Extractor
  def collate
    min_count = @all_things.map { |_k, v| v[:count] }.sort.last(Extractor::TOP_N)[0]
    @all_things.reject { |k, v| v[:count] < [min_count, Extractor::THRESHOLD].max }
  end

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

  # Yes, we want to override the superclass function with a no-op. Retweets
  # need to report texts, counts, AND links, not just items and counts; since
  # they're using a different data structure, #collate takes responsibility for
  # it, and we don't want to let #set_all_things mess it up.
  def set_all_things ; end
end
