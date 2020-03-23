# == Schema Information
#
# Table name: retweets
#
#  id          :bigint           not null, primary key
#  count       :integer
#  link        :string
#  text        :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  data_set_id :bigint
#
# Indexes
#
#  index_retweets_on_data_set_id  (data_set_id)
#

class Retweet < ApplicationRecord
  belongs_to :data_set
end
