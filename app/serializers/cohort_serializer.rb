# == Schema Information
#
# Table name: cohorts
#
#  id           :bigint           not null, primary key
#  description  :text
#  index_prefix :string
#  name         :text
#  twitter_ids  :text             default([]), is an Array
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class CohortSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id
  attribute :description
  attribute :twitter_ids
end
