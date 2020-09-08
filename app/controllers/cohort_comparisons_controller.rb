class CohortComparisonsController < ApplicationController
  before_action :load_cohort_comparison, only: [:show, :update]
  respond_to :json

  def index
    render json: CohortComparisonSerializer.new(
      CohortComparison.all
    ).serialized_json
  end

  def show
    render json: CohortComparisonSerializer.new(
      @cohort_comparison
    ).serialized_json
  end

  def update
    @cohort_comparison.results = params[:results]
    @cohort_comparison.save!
  end

  private

  def load_cohort_comparison
    @cohort_comparison = CohortComparison.where(
      cohort_a_id: params[:cohort_a_id],
      timespan_a_id: params[:timespan_a_id],
      cohort_b_id: params[:cohort_b_id],
      timespan_b_id: params[:timespan_b_id]).first
  end
end
