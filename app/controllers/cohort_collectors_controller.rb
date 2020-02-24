class CohortCollectorsController < ApplicationController
  respond_to :html, :js

  def index
    @cohort_collectors = CohortCollector.all.order(created_at: :desc)
  end

  def create
    @cohort_collector = CohortCollector.new(cohort_collector_params)

    if @cohort_collector.save
      flash.notice = 'Cohort collector created'
      redirect_to cohort_collectors_path(@cohort_collector)
    else
      render 'new'
    end
  end

  def show
    @cohort_collector = CohortCollector.find(params[:id])
  end

  def monitor
    cc = CohortCollector.find(params[:cohort_collector_id])
    @running = cc.monitor_twitter

    if @running
      flash[:notice] = "Data collection in process until approximately #{cc.end_time}."
    else
      flash[:warn] = "Something went wrong."
    end

    respond_to do |format|
      format.js
    end
  end

  def create_cohort
    cc = CohortCollector.find(params[:cohort_collector_id])
    cc.create_cohort

    respond_to do |format|
      format.js { flash[:notice] = 'Cohort created.' }
    end
  end

  private

  def cohort_collector_params
    params.require(:cohort_collector).permit(search_query_ids: [])
  end
end
