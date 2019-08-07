class MediaSourcesController < ApplicationController
  def index
    render json: MediaSourceSerializer.new(
      MediaSource.where(active: true)
    ).serialized_json
  end

  def show
    render json: MediaSourceSerializer.new(
      MediaSource.find(params[:id])
    ).serialized_json
  end

  # Given a list of media source IDs, returns the most recent data sets.
  # Expects a querystring of the form ids[]=1&ids[]=2&ids[]=3.
  # That also makes it easier to return a logical error message.
  def data
    data_hash = MediaSourceSerializer.new(
      available_sources, is_collection: true
    ).serializable_hash

    if available_sources.pluck(:id) != params[:ids]
      data_hash[:errors] = 'One or more specified MediaSources do not exist'
    end

    render json: data_hash.to_json
  end

  private

  def available_sources
    @available_sources ||= MediaSource.where(id: params[:ids])
  end
end
