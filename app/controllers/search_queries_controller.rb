class SearchQueriesController < ApplicationController
  def index
    @search_queries = SearchQuery.all.order(created_at: :desc)
  end

  def create
    @search_query = SearchQuery.new(search_query_params)

    if @search_query.save
      flash[:info] = 'Search query created'
      redirect_to search_query_path(@search_query)
    else
      render 'new'
    end
  end

  def show
    @search_query = SearchQuery.find(params[:id])
  end

  private

  def search_query_params
    params.permit(:name, :url, :description)
  end
end
