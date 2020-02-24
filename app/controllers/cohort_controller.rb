class CohortController < ApplicationController
  skip_before_filter :authenticate_user!

  def index
    render json: CohortSerializer.new(
      CohortSerializer.where(active: true)
    ).serialized_json
  end

  def show
    if params.include? :id
      show_one
    elsif params.include? :ids
      show_multiple
    else
      raise ActionController::ParameterMissing('/:id or ?ids[]=1&ids[]=2 must be supplied')
    end
  end

  private

  def show_one
    render json: CohortSerializer.new(
      Cohort.find(params[:id])
    ).serialized_json
  end

  # Given a list of cohort IDs, returns the most recent data sets for each, plus
  # the aggregated data across all.
  # Expects a querystring of the form ids[]=1&ids[]=2&ids[]=3.
  def show_multiple
    data = CohortSerializer.new(
      Cohort.where(id: params[:ids]), is_collection: true
    ).serializable_hash

    unless params_valid?
      data[:errors] = 'One or more specified Cohorts do not exist'
    end

    render json: data.to_json
  end

  def params_valid?
    # Each requested parameter should correspond to a Cohort that actually
    # exists, meaning that the number of parameters should equal the number of
    # Cohorts fetched from the db.
    # If someone has entered non-numeric params, they'll map to 0, so there's
    # no error to handle.
    integer_ids = params[:ids].map(&:to_i).reject { |i| i == 0 }
    integer_ids.length == Cohort.where(id: params[:ids]).count
  end
end
