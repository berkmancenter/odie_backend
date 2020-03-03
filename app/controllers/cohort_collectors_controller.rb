class CohortCollectorsController < ApplicationController
  after_action { flash.discard if request.xhr? }

  respond_to :html, :js

  def index
    @cohort_collectors = CohortCollector.all.order(created_at: :desc)
  end

  def create
    @cohort_collector = CohortCollector.new(cohort_collector_params)

    if @cohort_collector.save
      flash[:info] = 'Cohort collector created'
      redirect_to cohort_collector_path(@cohort_collector)
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
      flash[:info] = "Data collection in process until approximately #{cc.readable_time(cc.end_time)}."
    else
      flash[:warning] = "Something went wrong. Usually this means Elasticsearch isn't running and the geeks should restart it."
    end

    respond_to do |format|
      format.js
    end
  end

  def create_cohort
    cc = CohortCollector.find(params[:cohort_collector_id])
    cohort = cc.create_cohort

    add_feedback(cohort)
  rescue ActiveRecord::StatementInvalid
    flash[:warning] = 'Cohort could not be created.'
  rescue Faraday::ConnectionFailed
    flash[:warning] = 'Cohort could not be created because Elasticsearch is not running; talk to the geek team.'
  ensure
    respond_to do |format|
      format.js
    end
  end

  private

  def add_feedback(cohort)
    if cohort&.valid?
      flash[:notice] = 'Cohort created.'
    elsif cohort&.errors.present?
      flash[:warning] = "Cohort could not be created: #{cohort.errors}"
    else
      flash[:warning] = 'Cohort could not be created.'
    end
  end

  def cohort_collector_params
    params.require(:cohort_collector).permit(search_query_ids: [])
  end
end
