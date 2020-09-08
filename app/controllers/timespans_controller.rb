class TimespansController < ApplicationController
  respond_to :json

  def index
    render json: TimespanSerializer.new(
      Timespan.all
    ).serialized_json
  end
end
