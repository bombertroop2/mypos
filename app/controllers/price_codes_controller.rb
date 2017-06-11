include SmartListing::Helper::ControllerExtensions
class PriceCodesController < ApplicationController
  load_and_authorize_resource
  before_action :set_price_code, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper

  # GET /price_codes
  # GET /price_codes.json
  def index
    like_command =  if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    price_codes_scope = PriceCode.select(:id, :code, :name, :description)
    price_codes_scope = price_codes_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(price_codes_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(price_codes_scope.where(["description #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @price_codes = smart_listing_create(:price_codes, price_codes_scope, partial: 'price_codes/listing', default_sort: {code: "asc"})
  end

  # GET /price_codes/1
  # GET /price_codes/1.json
  def show
  end

  # GET /price_codes/new
  def new
    @price_code = PriceCode.new
  end

  # GET /price_codes/1/edit
  def edit
  end

  # POST /price_codes
  # POST /price_codes.json
  def create
    @price_code = PriceCode.new(price_code_params)

    begin
      @price_code.save
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{price_codes_url}'"
    end

  end

  # PATCH/PUT /price_codes/1
  # PATCH/PUT /price_codes/1.json
  def update
    begin        
      @price_code.update(price_code_params)
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{price_codes_url}'"
    end
  end

  # DELETE /price_codes/1
  # DELETE /price_codes/1.json
  def destroy
    @price_code.destroy
    
    if @price_code.errors.present? and @price_code.errors.messages[:base].present?
      error_message = @price_code.errors.messages[:base].to_sentence
      error_message.slice! "details "
      flash[:alert] = error_message
      render js: "window.location = '#{price_codes_url}'"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_price_code
    @price_code = PriceCode.where(id: params[:id]).select(:id, :code, :name, :description).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def price_code_params
    params.require(:price_code).permit(:code, :name, :description)
  end
end
