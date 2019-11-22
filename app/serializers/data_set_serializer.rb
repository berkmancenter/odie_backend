# == Schema Information
#
# Table name: data_sets
#
#  id              :bigint           not null, primary key
#  hashtags        :hstore
#  index_name      :string
#  num_retweets    :integer
#  num_tweets      :integer
#  num_users       :integer
#  top_mentions    :hstore
#  top_sources     :hstore
#  top_urls        :hstore
#  top_words       :hstore
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  data_config_id  :bigint
#  media_source_id :bigint
#
# Indexes
#
#  index_data_sets_on_data_config_id   (data_config_id)
#  index_data_sets_on_media_source_id  (media_source_id)
#
# Foreign Keys
#
#  fk_rails_...  (data_config_id => data_configs.id)
#

class DataSetSerializer
  include FastJsonapi::ObjectSerializer
  attributes :num_users, :num_tweets, :num_retweets, :index_name, :hashtags
end
