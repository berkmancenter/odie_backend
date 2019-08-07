class DataSetSerializer
  include FastJsonapi::ObjectSerializer
  attributes :num_users, :num_tweets, :num_retweets, :index_name, :hashtags
end
