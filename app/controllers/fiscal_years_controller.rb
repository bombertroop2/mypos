include SmartListing::Helper::ControllerExtensions
class FiscalYearsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_fiscal_year, only: [:show, :edit, :update, :destroy]
  before_action :add_year_to_child, only: [:create, :update]

  # GET /fiscal_years
  # GET /fiscal_years.json
  def index
    like_command = "ILIKE"
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
    unless @valid = @fiscal_year.save
      if @fiscal_year.errors[:"fiscal_months.base"].present?
        render js: "bootbox.alert({message: \"#{@fiscal_year.errors[:"fiscal_months.base"].join("<br/>")}\",size: 'small'});"
      end
    end
  end

  # PATCH/PUT /fiscal_years/1
  # PATCH/PUT /fiscal_years/1.json
  def update
    unless @valid = @fiscal_year.update(fiscal_year_params)
      if @fiscal_year.errors[:"fiscal_months.base"].present?
        render js: "bootbox.alert({message: \"#{@fiscal_year.errors[:"fiscal_months.base"].join("<br/>")}\",size: 'small'});"
      end
    end
  end

  # DELETE /fiscal_years/1
  # DELETE /fiscal_years/1.json
  def destroy    
    unless @fiscal_year.destroy
      @deleted = false
    else
      @deleted = true
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_fiscal_year
    @fiscal_year = FiscalYear.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def fiscal_year_params
    params.require(:fiscal_year).permit(:year, fiscal_months_attributes: [:month, :status, :id, :year])
  end
  
  def add_year_to_child
    params[:fiscal_year][:fiscal_months_attributes].each do |key, value|
      params[:fiscal_year][:fiscal_months_attributes][key].merge! year: params[:fiscal_year][:year]
    end if params[:fiscal_year][:fiscal_months_attributes].present?
  end
end
