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
  def aggregate
    data_hash = MediaSourceSerializer.new(
      available_sources, is_collection: true
    ).serializable_hash

    unless params_valid?
      data_hash[:errors] = 'One or more specified MediaSources do not exist'
    end

    render json: data_hash.to_json
  end

  private

  def available_sources
    @available_sources ||= MediaSource.where(id: params[:ids])
  end

  def params_valid?
    # The params requested should be a subset of the available sources. If this
    # is true, subtracting the available sources will result in an empty set.
    # If someone has entered non-numeric params, they'll map to 0, so there's
    # no error to handle.
    integer_ids = params[:ids].map(&:to_i)
    ( integer_ids - available_sources.pluck(:id) ).empty?
  end
end
