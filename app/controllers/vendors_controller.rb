include SmartListing::Helper::ControllerExtensions
class VendorsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_vendor, only: [:show, :edit, :update, :destroy]

  # GET /vendors
  # GET /vendors.json
  def index
    like_command =  if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    vendors_scope = Vendor.select(:id, :code, :name, :phone, :facsimile, :email)
    vendors_scope = vendors_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(vendors_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(vendors_scope.where(["phone #{like_command} ?", "%"+params[:filter]+"%"])).
      or(vendors_scope.where(["facsimile #{like_command} ?", "%"+params[:filter]+"%"])).
      or(vendors_scope.where(["email #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @vendors = smart_listing_create(:vendors, vendors_scope, partial: 'vendors/listing', default_sort: {code: "asc"})
  end

  # GET /vendors/1
  # GET /vendors/1.json
  def show
  end

  # GET /vendors/new
  def new
    @vendor = Vendor.new is_taxable_entrepreneur: true
  end

  # GET /vendors/1/edit
  def edit
  end

  # POST /vendors
  # POST /vendors.json
  def create
    @vendor = Vendor.new(vendor_params)

    begin
      @vendor.save
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{vendors_url}'"
    end

  end

  # PATCH/PUT /vendors/1
  # PATCH/PUT /vendors/1.json
  def update
    begin        
      @vendor.update(vendor_params)
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{vendors_url}'"
    end
  end

  # DELETE /vendors/1
  # DELETE /vendors/1.json
  def destroy
    @vendor.destroy
    
    if @vendor.errors.present? and @vendor.errors.messages[:base].present?
      flash[:alert] = @vendor.errors.messages[:base].to_sentence
      render js: "window.location = '#{vendors_url}'"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_vendor
    @vendor = Vendor.where(id: params[:id]).select(:id, :code, :name, :address, :phone, :facsimile, :email, :pic_name, :pic_phone, :pic_mobile_phone, :pic_email, :terms_of_payment, :value_added_tax, :is_taxable_entrepreneur).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def vendor_params
    params.require(:vendor).permit(:is_taxable_entrepreneur, :terms_of_payment, :value_added_tax, :code, :name, :phone, :facsimile, :email, :pic_name, :pic_phone, :pic_mobile_phone, :pic_email, :address)
  end
end
