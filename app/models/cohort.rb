# == Schema Information
#
# Table name: cohorts
#
#  id           :bigint           not null, primary key
#  description  :text
#  index_prefix :string
#  twitter_ids  :text             default([]), is an Array
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Cohort < ApplicationRecord
  after_save :update_data_collection

  private

  def update_data_collection
    StreamingDataCollector.write_conf
  end
end
