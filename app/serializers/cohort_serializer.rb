# == Schema Information
#
# Table name: search_queries
#
#  id          :bigint           not null, primary key
#  active      :boolean
#  description :text
#  keyword     :string
#  name        :string
#  url         :string
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
