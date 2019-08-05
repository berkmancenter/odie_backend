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

end
