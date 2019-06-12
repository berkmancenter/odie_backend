class MediaSourcesSerializer
  include FastJsonapi::ObjectSerializer
  attributes :description, :name, :url

  attribute :latest_index do |obj|
    obj.data_sets&.last&.index_name
  end
end
