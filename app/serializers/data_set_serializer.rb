# == Schema Information
#
# Table name: data_sets
#
#  id           :bigint           not null, primary key
#  hashtags     :hstore
#  index_name   :string
#  num_retweets :integer
#  num_tweets   :integer
#  num_users    :integer
#  top_mentions :hstore
#  top_sources  :hstore
#  top_urls     :hstore
#  top_words    :hstore
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  cohort_id    :bigint
#
# Indexes
#
#  index_data_sets_on_cohort_id  (cohort_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#

class DataSetSerializer
  include FastJsonapi::ObjectSerializer
  attributes :num_users, :num_tweets, :num_retweets, :index_name, :hashtags,
             :top_mentions, :top_retweets, :top_sources, :top_urls, :top_words
end
