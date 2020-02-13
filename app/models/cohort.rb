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
  has_many :data_sets

  # Given a list of cohort IDs, returns aggregated metadata from their most
  # recent DataSets.
  def self.aggregate(ids)
    DataSet.aggregate(
      self.where(id: ids).map(&:latest_data_set)
    )
  end

  def collect_data
    DataSet.create(cohort: self).run_pipeline
  end

  def latest_data_set
    data_sets.last
  end
end
