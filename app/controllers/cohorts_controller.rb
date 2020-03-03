class CohortsController < ApplicationController
  skip_before_action :authenticate_user!
  after_action { flash.discard if request.xhr? }

  def index
    return index_json unless current_user&.admin?

    respond_to do |format|
      format.json { index_json }
      format.html
    end
  end

  def show
    show_json unless current_user&.admin?

    @cohort = Cohort.find(params[:id])

    respond_to do |format|
      format.json { show_json }
      format.html
    end
  end

  def create
    @cohort = Cohort.new(cohort_params)

    if @cohort.save
      flash[:info] = 'Cohort created'
      redirect_to cohort_path(@cohort)
    else
      render 'new'
    end
  end

  def collect_data
    Cohort.find(params[:cohort_id]).collect_data

    flash[:info] = 'Data collection in process'
  rescue Faraday::ConnectionFailed => error
    Rails.logger.warn("Failed collection data for cohort #{params[:cohort_id]}: #{error}")
    flash[:warning] = "Data can't be collected because Elasticsearch isn't running. Talk to the geeks."
  rescue Exception => error
    Rails.logger.warn("Failed collection data for cohort #{params[:cohort_id]}: #{error}")
    flash[:warning] = 'Something went wrong.'
  ensure
    respond_to do |format|
      format.js
    end
  end

  private

  def index_json
    render json: CohortSerializer.new(
      Cohort.all
    ).serialized_json
  end

  def show_json
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

  def cohort_params
    params.permit(:description)
          .merge({ twitter_ids: params[:twitter_ids].split(',') })
  end
end
