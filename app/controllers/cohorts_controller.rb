class CohortsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    index_js unless current_user&.admin?

    respond_to do |format|
      format.js { index_js }
      format.html
    end
  end

  def show
    show_js unless current_user&.admin?

    @cohort = Cohort.find(params[:id])

    respond_to do |format|
      format.js { show_js }
      format.html
    end
  end

  private

  def index_js
    render json: CohortSerializer.new(
      Cohort.all
    ).serialized_json
  end

  def show_js
    if params.include? :id
      show_one
    elsif params.include? :ids
      show_multiple
    else
      raise ActionController::ParameterMissing('/:id or ?ids[]=1&ids[]=2 must be supplied')
    end
  end

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
