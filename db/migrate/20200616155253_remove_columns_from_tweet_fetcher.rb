class RemoveColumnsFromTweetFetcher < ActiveRecord::Migration[5.2]
  def change
    remove_column :tweet_fetchers, :complete, :boolean
    remove_column :tweet_fetchers, :user_id, :string
    remove_column :tweet_fetchers, :backoff, :integer
  end
end
