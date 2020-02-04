class DataSetCsverizer < ActiveModel::Csverizer
  attributes :num_users, :num_tweets, :num_retweets, :index_name, :hashtags,
             :top_mentions, :top_retweets, :top_sources, :top_urls, :top_words
end
