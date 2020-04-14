class MentionExtractor < Extractor
  private

  def extract
    # The first step extracts a list of items of the form
    # {item: Twitter::Entity::UserMention, user_id: Integer}.
    # The second removes any empty lists (i.e. tweets without mentions).
    # The third keeps track of which users (screen_names) have been mentioned
    # by which users (user_id).
    @tweets.map { |tweet| all_nested_with_user(:user_mentions, tweet) }
           .flatten
           .each do |item_user|
             @working_space[item_user[:item].screen_name] << item_user[:user_id]
           end
  end
end
