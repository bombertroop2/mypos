include SmartListing::Helper::ControllerExtensions
class CompaniesController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_company, only: [:show, :edit, :update, :destroy]

  # GET /companies
  # GET /companies.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    companies_scope = Company.select(:id, :code, :name, :address, :phone)
    companies_scope = companies_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(companies_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(companies_scope.where(["address #{like_command} ?", "%"+params[:filter]+"%"])).
      or(companies_scope.where(["phone #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @companies = smart_listing_create(:companies, companies_scope, partial: 'companies/listing', default_sort: {code: "asc"})
  end

  # GET /companies/1
  # GET /companies/1.json
  def show
  end

  # GET /companies/new
  def new
    @company = Company.new
  end

  # GET /companies/1/edit
  def edit
  end

  # POST /companies
  # POST /companies.json
  def create
    @company = Company.new(company_params)
    @created = @company.save
  end

  # PATCH/PUT /companies/1
  # PATCH/PUT /companies/1.json
  def update
    @updated = @company.update(company_params)
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    @company.destroy
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_company
    @company = Company.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def company_params
    params.require(:company).permit(:code, :name, :taxpayer_registration_number, :address, :phone, :fax, :total_showroom, :total_counter)
  end
end
