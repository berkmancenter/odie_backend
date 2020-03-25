class RetweetExtractor < Extractor
  def accumulate(data_sets, key)
    @all_things = data_sets.map(&:top_retweets)
      .flatten(1)
      .reduce({}) do |first, second|
        first.merge(second) do |_, a, b|
          { count: a[:count].to_i + b[:count].to_i, link: a[:link] }
        end
      end

    self
  end

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

  def set_all_things ; end
end
