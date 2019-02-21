class ExploreController < ApplicationController
  include ApplicationHelper

  def index
    respond_to do |format|
      format.html do
        @download_url = build_csv_url
        @search = search
        @results = search.results.page params[:page]
      end
      format.csv do
        send_csv
      end
    end
  end

  private

  def build_csv_url
    explore_path(params
      .to_unsafe_hash.merge(format: 'csv'))
  end

  def search
    CompanySearch.new(criteria_params)
  end

  def send_csv
    results = StatementSearch.new(criteria_params).results
    send_data StatementExport.to_csv(results, admin?), filename: csv_filename
  end

  def criteria_params
    {
      industries: params[:industries],
      countries: params[:countries],
      company_name: params[:company_name],
      legislations: params[:legislations]
    }
  end

  def csv_filename
    "modernslaveryregistry-#{Time.zone.today}.csv"
  end
end
