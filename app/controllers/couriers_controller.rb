include SmartListing::Helper::ControllerExtensions
class CouriersController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_courier, only: [:show, :edit, :update, :destroy]

  # GET /couriers
  # GET /couriers.json
  def index
    like_command = "ILIKE"
    couriers_scope = Courier.select(:id, :code, :name, :via, :unit, :status)
    couriers_scope = couriers_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(couriers_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(couriers_scope.where(["via #{like_command} ?", "%"+params[:filter]+"%"])).
      or(couriers_scope.where(["unit #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @couriers = smart_listing_create(:couriers, couriers_scope, partial: 'couriers/listing', default_sort: {code: "asc"})
  end

  # GET /couriers/1
  # GET /couriers/1.json
  def show
  end

  # GET /couriers/new
  def new
    @courier = Courier.new
  end

  # GET /couriers/1/edit
  def edit
  end

  # POST /couriers
  # POST /couriers.json
  def create
    convert_price_to_numeric
    @courier = Courier.new(courier_params)

    @invalid = !@courier.save
  rescue ActiveRecord::RecordNotUnique => e
    render js: "bootbox.alert({message: 'Price should be unique!', size: 'small'})"
  end

  # PATCH/PUT /couriers/1
  # PATCH/PUT /couriers/1.json
  def update
    @invalid = !@courier.update(courier_params)
  end

  # DELETE /couriers/1
  # DELETE /couriers/1.json
  def destroy
    @courier.destroy    
    if @courier.errors.present? && @courier.errors.messages[:base].present?
      flash[:alert] = @courier.errors.messages[:base].to_sentence
      render js: "window.location = '#{couriers_url}'"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_courier
    @courier = Courier.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def courier_params
    if action_name.eql?("create")
      params.require(:courier).permit(:code, :name, :via, :unit, :status,
        courier_prices_attributes: [:city_id, :effective_date, :price_type, :price, :_destroy])
    else
      params.require(:courier).permit(:code, :name, :via, :unit, :status)
    end
  end
  
  def convert_price_to_numeric
    params[:courier][:courier_prices_attributes].each do |key, value|
      params[:courier][:courier_prices_attributes][key][:price] = params[:courier][:courier_prices_attributes][key][:price].gsub("Rp","").gsub(".","").gsub(",",".")
    end if params[:courier][:courier_prices_attributes].present?
  end
end
