# == Schema Information
#
# Table name: media_sources
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

class MediaSourceSerializer
  include FastJsonapi::ObjectSerializer
  attributes :description, :name, :url

  attribute :latest_data do |obj|
    if (data = obj.latest_data)
      DataSetSerializer.new(data).serializable_hash
    else
      nil
    end
  end
end
