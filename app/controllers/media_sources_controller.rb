class MediaSourcesController < ApplicationController
  def index
    render json: MediaSourcesSerializer.new(
      MediaSource.where(active: true)
    ).serialized_json
  end

  def show
    render json: MediaSourcesSerializer.new(
      MediaSource.find(params[:id])
    ).serialized_json
  end
end
