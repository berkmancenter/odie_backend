class CohortSummariesController < ApplicationController
  before_action :load_cohort_summary, only: [:show, :update]
  respond_to :json

  def index
    render json: CohortSummarySerializer.new(
      CohortSummary.all
    ).serialized_json
  end

  def show
    render json: CohortSummarySerializer.new(
      @cohort_summary
    ).serialized_json
  end

  def update
    @cohort_summary.results = params[:results]
    @cohort_summary.save!
  end

  private

  def load_cohort_summary
    @cohort_summary = CohortSummary.where(
      cohort_id: params[:id], timespan_id: params[:timespan_id]).first
  end
end
