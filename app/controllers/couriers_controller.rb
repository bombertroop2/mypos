include SmartListing::Helper::ControllerExtensions
class CouriersController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_courier, only: [:show, :edit, :update, :destroy]

  # GET /couriers
  # GET /couriers.json
  def index
    like_command = "ILIKE"
    couriers_scope = Courier.select(:id, :code, :name, :status)
    couriers_scope = couriers_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(couriers_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @couriers = smart_listing_create(:couriers, couriers_scope, partial: 'couriers/listing', default_sort: {code: "asc"})
  end

  # GET /couriers/1
  # GET /couriers/1.json
  def show
  end

  # GET /couriers/new
  def new
    @courier = Courier.new
    courier_way = @courier.courier_ways.build name: "Land"
    courier_way.courier_units.build name: "Cubic"
    courier_way.courier_units.build name: "Kilogram"
    courier_way = @courier.courier_ways.build name: "Sea"
    courier_way.courier_units.build name: "Cubic"
    courier_way.courier_units.build name: "Kilogram"
    courier_way = @courier.courier_ways.build name: "Air"
    courier_way.courier_units.build name: "Cubic"
    courier_way.courier_units.build name: "Kilogram"
  end

  # GET /couriers/1/edit
  def edit
    if (courier_way = @courier.courier_ways.select{|cw| cw.name.eql?("Land")}.first).blank?
      courier_way = @courier.courier_ways.build name: "Land"
      courier_way.courier_units.build name: "Cubic"
      courier_way.courier_units.build name: "Kilogram"
    else
      if courier_way.courier_units.select("1 AS one").where(name: "Cubic").blank?
        courier_way.courier_units.build name: "Cubic"
      end
      if courier_way.courier_units.select("1 AS one").where(name: "Kilogram").blank?        
        courier_way.courier_units.build name: "Kilogram"
      end
    end
    if (courier_way = @courier.courier_ways.select{|cw| cw.name.eql?("Sea")}.first).blank?
      courier_way = @courier.courier_ways.build name: "Sea"
      courier_way.courier_units.build name: "Cubic"
      courier_way.courier_units.build name: "Kilogram"
    else
      if courier_way.courier_units.select("1 AS one").where(name: "Cubic").blank?        
        courier_way.courier_units.build name: "Cubic"
      end
      if courier_way.courier_units.select("1 AS one").where(name: "Kilogram").blank?        
        courier_way.courier_units.build name: "Kilogram"
      end
    end
    if (courier_way = @courier.courier_ways.select{|cw| cw.name.eql?("Air")}.first).blank?
      courier_way = @courier.courier_ways.build name: "Air"
      courier_way.courier_units.build name: "Cubic"
      courier_way.courier_units.build name: "Kilogram"
    else
      if courier_way.courier_units.select("1 AS one").where(name: "Cubic").blank?        
        courier_way.courier_units.build name: "Cubic"
      end
      if courier_way.courier_units.select("1 AS one").where(name: "Kilogram").blank?        
        courier_way.courier_units.build name: "Kilogram"
      end
    end
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
  rescue ActiveRecord::InvalidForeignKey => e
    render js: "bootbox.alert({message: \"Cannot delete record because dependent packing lists exist\",size: 'small'});"
  rescue ActiveRecord::RecordNotDestroyed => e
    render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
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
      params.require(:courier).permit(:code, :name, :status, :terms_of_payment, :value_added_tax_type,
        courier_ways_attributes: [:name, :_destroy,
          courier_units_attributes: [:name, :_destroy]])
    else
      params.require(:courier).permit(:code, :name, :status, :terms_of_payment, :value_added_tax_type,
        courier_ways_attributes: [:name, :_destroy, :id,
          courier_units_attributes: [:name, :_destroy, :id]])
    end
  end
end
