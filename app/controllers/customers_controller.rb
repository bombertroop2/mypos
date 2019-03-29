include SmartListing::Helper::ControllerExtensions
class CustomersController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_customer, only: [:show, :edit, :update, :destroy]
  before_action :convert_limit_value_to_numeric, only: [:create, :update]

  # GET /customers
  # GET /customers.json
  def index
    like_command = "ILIKE"
    customers_scope = Customer.select(:id, :code, :name, :phone, :facsimile, :email)
    customers_scope = customers_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(customers_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(customers_scope.where(["phone #{like_command} ?", "%"+params[:filter]+"%"])).
      or(customers_scope.where(["facsimile #{like_command} ?", "%"+params[:filter]+"%"])).
      or(customers_scope.where(["email #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @customers = smart_listing_create(:customers, customers_scope, partial: 'customers/listing', default_sort: {code: "asc"})
  end

  # GET /customers/1
  # GET /customers/1.json
  def show
  end

  # GET /customers/new
  def new
    @customer = Customer.new is_taxable_entrepreneur: true
  end

  # GET /customers/1/edit
  def edit
  end

  # POST /customers
  # POST /customers.json
  def create
    @customer = Customer.new(customer_params)

    begin
      @customer.save
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{customers_url}'"
    end

  end

  # PATCH/PUT /customers/1
  # PATCH/PUT /customers/1.json
  def update
    begin        
      @customer.update(customer_params)
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{customers_url}'"
    end
  end

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy
    @customer.destroy
    
    if @customer.errors.present? and @customer.errors.messages[:base].present?
      flash[:alert] = @customer.errors.messages[:base].to_sentence
      render js: "window.location = '#{customers_url}'"
    end
  end
  
  def get_cities
    @cities = City.select(:id, :name).where(province_id: params[:province_id]).order(:name)
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_customer
    @customer = Customer.where(id: params[:id]).select(:id, :code, :name, :address, :phone, :facsimile, :email, :pic_name, :pic_mobile_phone, :pic_email, :terms_of_payment, :value_added_tax, :is_taxable_entrepreneur, :limit_value, :deliver_to, :province_id, :city_id, :unlimited, :discount).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def customer_params
    params.require(:customer).permit(:province_id, :city_id, :is_taxable_entrepreneur, :terms_of_payment, :value_added_tax, :code, :name, :phone, :facsimile, :email, :pic_name,  :pic_mobile_phone, :pic_email, :address, :limit_value, :deliver_to, :unlimited, :discount)
  end
  
  def convert_limit_value_to_numeric
    params[:customer][:limit_value] = params[:customer][:limit_value].gsub("Rp","").gsub(".","").gsub(",",".") if params[:customer][:limit_value].present?
  end
end
