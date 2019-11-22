class MentionExtractor < Extractor
  private

  def extract
    @tweets.map { |tweet| all_nested(:user_mentions, tweet) }
           .flatten
           .map { |mention_obj| mention_obj.screen_name }
           .each do |mention|
             all_things[mention] += 1
           end
    end
end
