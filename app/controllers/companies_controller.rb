include SmartListing::Helper::ControllerExtensions
class CompaniesController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_company, only: [:show, :edit, :update, :destroy]

  # GET /companies
  # GET /companies.json
  def index
    like_command = "ILIKE"
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
    add_additional_params_to_child
    @company = Company.new(company_params)
    unless @created = @company.save
      if @company.errors[:base].present?
        render js: "bootbox.alert({message: \"#{@company.errors[:base].join("<br/>")}\",size: 'small'});"
      end
    end
  rescue ActiveRecord::RecordNotUnique => e
    if e.message.index("index_company_banks_on_company_id_and_code").present?
      render js: "bootbox.alert({message: 'Bank code should be unique!', size: 'small'})"
    elsif e.message.index("index_cban_on_company_bank_id_and_account_number").present?
      render js: "bootbox.alert({message: 'Bank account number should be unique!', size: 'small'})"     
    end
  end

  # PATCH/PUT /companies/1
  # PATCH/PUT /companies/1.json
  def update
    add_additional_params_to_child
    @updated = @company.update(company_params)
  rescue ActiveRecord::RecordNotUnique => e
    if e.message.index("index_company_banks_on_company_id_and_code").present?
      render js: "bootbox.alert({message: 'Bank code should be unique!', size: 'small'})"
    elsif e.message.index("index_cban_on_company_bank_id_and_account_number").present?
      render js: "bootbox.alert({message: 'Bank account number should be unique!', size: 'small'})"     
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    render js: "bootbox.alert({message: 'Failed to remove account number', size: 'small'})"     
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    if !@company.destroy && @company.errors.messages[:base].present?
      render js: "bootbox.alert({message: \"#{@company.errors.messages[:base].join("<br/>")}\",size: 'small'});"
    end
  end

  private
  
  def add_additional_params_to_child
    params[:company][:company_banks_attributes].each do |key, value|
      params[:company][:company_banks_attributes][key][:company_bank_account_numbers_attributes].each do |k, v|
        params[:company][:company_banks_attributes][key][:company_bank_account_numbers_attributes][k][:attr_bank_code] = params[:company][:company_banks_attributes][key][:code]
      end if params[:company][:company_banks_attributes][key][:company_bank_account_numbers_attributes].present?
    end if params[:company][:company_banks_attributes].present?
  end
  
  # Use callbacks to share common setup or constraints between actions.
  def set_company
    @company = Company.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def company_params
    params.require(:company).permit(:code, :name, :taxpayer_registration_number, :address, :phone, :fax, :total_showroom, :total_counter, :import_beginning_stock,
      company_banks_attributes: [:id, :code, :name, :_destroy,
        company_bank_account_numbers_attributes: [:id, :account_number, :_destroy, :attr_bank_code]])
  end
end
