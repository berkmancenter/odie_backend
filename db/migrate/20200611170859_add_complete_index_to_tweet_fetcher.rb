class AddCompleteIndexToTweetFetcher < ActiveRecord::Migration[5.2]
  def change
    add_index :tweet_fetchers, :complete
  end
end
