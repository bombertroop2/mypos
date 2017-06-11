include SmartListing::Helper::ControllerExtensions
class CouriersController < ApplicationController
  load_and_authorize_resource
  helper SmartListing::Helper
  before_action :set_courier, only: [:show, :edit, :update, :destroy]

  # GET /couriers
  # GET /couriers.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    couriers_scope = Courier.select(:id, :code, :name, :via, :unit)
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
    @courier = Courier.new(courier_params)

    @invalid = !@courier.save
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
    params.require(:courier).permit(:code, :name, :via, :unit)
  end
end
