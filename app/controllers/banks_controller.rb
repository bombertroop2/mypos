include SmartListing::Helper::ControllerExtensions
class BanksController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_bank, only: [:show, :edit, :update, :destroy]

  # GET /banks
  # GET /banks.json
  def index
    like_command = "ILIKE"
    banks_scope = Bank.select(:id, :code, :name, :card_type)
    banks_scope = banks_scope.where(["code #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(banks_scope.where(["name #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    banks_scope = banks_scope.where(["card_type = ?", params[:filter_type]]) if params[:filter_type].present?
    @banks = smart_listing_create(:banks, banks_scope, partial: 'banks/listing', default_sort: {code: "asc"})
  end

  # GET /banks/1
  # GET /banks/1.json
  def show
  end

  # GET /banks/new
  def new
    @bank = Bank.new
  end

  # GET /banks/1/edit
  def edit
  end

  # POST /banks
  # POST /banks.json
  def create
    @bank = Bank.new(bank_params)
    begin
      @valid = @bank.save
    rescue ActiveRecord::RecordNotUnique => e
      @valid = false      
      @bank.errors.messages[:code] = ["has already been taken"]
    end
  end

  # PATCH/PUT /banks/1
  # PATCH/PUT /banks/1.json
  def update
    begin
      @valid = @bank.update(bank_params)
    rescue ActiveRecord::RecordNotUnique => e   
      @valid = false      
      @bank.errors.messages[:code] = ["has already been taken"]
    end
  end

  # DELETE /banks/1
  # DELETE /banks/1.json
  def destroy
    @deleted = @bank.destroy
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_bank
    @bank = Bank.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def bank_params
    params.require(:bank).permit(:code, :name, :card_type)
  end
end
