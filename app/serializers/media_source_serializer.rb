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
