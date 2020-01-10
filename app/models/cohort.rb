# == Schema Information
#
# Table name: cohorts
#
#  id          :bigint           not null, primary key
#  description :text
#  twitter_ids :text             default([]), is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Cohort < ApplicationRecord
  # Given a list of cohort IDs, returns aggregated metadata from their most
  # recent DataRuns.
  def self.aggregate(ids)
    DataSet.aggregate(
      self.where(id: ids).map(&:latest_data_run)
    )
  end
end
