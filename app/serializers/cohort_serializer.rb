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

class CohortSerializer
  include FastJsonapi::ObjectSerializer
  attribute :description

  attribute :latest_data do |obj|
    if (data = obj.latest_data_set)
      DataSetSerializer.new(data).serializable_hash
    else
      nil
    end
  end

  def serializable_hash
    hsh = super
    if is_collection?(@resource, @is_collection)
      hsh[:aggregates] = aggregates
    end
    hsh
  end

  private

  def aggregates
    Cohort.aggregate(@resource.pluck(:id))
  end
end
