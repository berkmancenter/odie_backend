class CohortCsverizer < ActiveModel::Csverizer
  attributes :description, :twitter_ids, :latest_data

  def twitter_ids
    object.twitter_ids.join(',')
  end

  def latest_data
    DataSetSerializer.new(object.latest_data_set).to_json
  end
end
