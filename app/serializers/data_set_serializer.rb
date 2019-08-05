class DataSetSerializer
  include FastJsonapi::ObjectSerializer
  attributes :num_users, :num_tweets, :num_retweets, :index_name, :hashtags

  # belongs_to only reports the type and ID of the media source; we want to
  # report all the associated data here so it can be fetched in one call.
  attribute :media_source do |dataset|
    MediaSourceSerializer.new(dataset.media_source).serializable_hash
  end
end
