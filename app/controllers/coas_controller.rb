include SmartListing::Helper::ControllerExtensions
class CoasController < ApplicationController
  authorize_resource
  helper SmartListing::Helper
  before_action :set_coa, only: [:show, :edit, :update, :destroy]

  # GET /coas
  # GET /coas.json
  def index
    coas_scope = AccountingAccount.filters(params[:q] || {})
    @coas = smart_listing_create(:coas, coas_scope, partial: 'coas/listing', default_sort: {code: "ASC"})
  end

  # GET /coas/1
  # GET /coas/1.json
  def show
  end

  # GET /coas/new
  def new
    @coa = AccountingAccount.new
  end

  # GET /coas/1/edit
  def edit
  end

  # POST /coas
  # POST /coas.json
  def create
    @coa = AccountingAccount.new(coa_params)
    begin
      @created = @coa.save
    rescue ActiveRecord::RecordNotUnique => e
      @created = false
      if e.message.include?("index_coas_on_transaction_type")
        @coa.errors.messages[:transaction_type] = ["has already been taken"]
      else
        @coa.errors.messages[:code] = ["has already been taken"]
      end
    end
  end

  # PATCH/PUT /coas/1
  # PATCH/PUT /coas/1.json
  def update
    begin
      @updated = @coa.update(coa_params)
    rescue ActiveRecord::RecordNotUnique => e
      @updated = false
      if e.message.include?("index_coas_on_transaction_type")
        @coa.errors.messages[:transaction_type] = ["has already been taken"]
      else
        @coa.errors.messages[:code] = ["has already been taken"]
      end
    end
  end

  # DELETE /coas/1
  # DELETE /coas/1.json
  def destroy
    @coa.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_coa
      @coa = AccountingAccount.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def coa_params
      params.require(:accounting_account).permit(:code, :classification, :description, :category_id)
    end
end
