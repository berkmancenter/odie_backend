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
             if @all_things[tweet[:text]].zero?
               @all_things[tweet[:text]] = {
                 count: 1,
                 link: tweet[:link]
               }
             else
               @all_things[tweet[:text]][:count] += 1
             end
           end
  end

  def collate
    # Only report the top N ranks (including ties), and don't report anything
    # below the threshold.
    min_count = @all_things.values.sort.last(TOP_N)[0]
    @all_things.reject { |k, v| v < [min_count, THRESHOLD].max }
    @all_things.transform_values(&:to_json)
  end
end
