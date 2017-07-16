include SmartListing::Helper::ControllerExtensions
class FiscalYearsController < ApplicationController
  load_and_authorize_resource
  helper SmartListing::Helper
  before_action :set_fiscal_year, only: [:show, :edit, :update, :destroy]

  # GET /fiscal_years
  # GET /fiscal_years.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    fiscal_years_scope = FiscalYear.select(:id, :year)
    fiscal_years_scope = fiscal_years_scope.where(["year #{like_command} ?", "%"+params[:filter]+"%"]) if params[:filter]
    @fiscal_years = smart_listing_create(:fiscal_years, fiscal_years_scope, partial: 'fiscal_years/listing', default_sort: {year: "asc"})
  end

  # GET /fiscal_years/1
  # GET /fiscal_years/1.json
  def show
  end

  # GET /fiscal_years/new
  def new
    @fiscal_year = FiscalYear.new
    FiscalMonth::MONTHS.each do |key, value|
      @fiscal_year.fiscal_months.build month: value, status: "Open"
    end
  end

  # GET /fiscal_years/1/edit
  def edit
  end

  # POST /fiscal_years
  # POST /fiscal_years.json
  def create
    @fiscal_year = FiscalYear.new(fiscal_year_params)
    @valid = @fiscal_year.save
  end

  # PATCH/PUT /fiscal_years/1
  # PATCH/PUT /fiscal_years/1.json
  def update
    @valid = @fiscal_year.update(fiscal_year_params)
  end

  # DELETE /fiscal_years/1
  # DELETE /fiscal_years/1.json
  def destroy
    @fiscal_year.destroy
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_fiscal_year
    @fiscal_year = FiscalYear.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def fiscal_year_params
    params.require(:fiscal_year).permit(:year, fiscal_months_attributes: [:month, :status, :id])
  end
end
