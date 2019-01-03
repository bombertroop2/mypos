include SmartListing::Helper::ControllerExtensions
class PackingListsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_packing_list, only: [:show, :destroy, :print]

  # GET /packing_lists
  # GET /packing_lists.json
  def index
    if params[:filter_departure_date].present?
      splitted_departure_date_range = params[:filter_departure_date].split("-")
      start_departure_date = splitted_departure_date_range[0].strip.to_date
      end_departure_date = splitted_departure_date_range[1].strip.to_date
    end

    packing_lists_scope = PackingList.select(:id, :number, :departure_date, :status, "couriers.code", "couriers.name").joins(courier_unit: [courier_way: :courier])
    packing_lists_scope = packing_lists_scope.where(["number ILIKE ?", "%"+params[:filter_number]+"%"]) if params[:filter_number].present?
    packing_lists_scope = packing_lists_scope.where(["courier_id = ?", params[:filter_courier]]) if params[:filter_courier].present?
    packing_lists_scope = packing_lists_scope.where(["departure_date BETWEEN ? AND ?", start_departure_date, end_departure_date]) if params[:filter_departure_date].present?
    packing_lists_scope = packing_lists_scope.where(["packing_lists.status = ?", params[:filter_status]]) if params[:filter_status].present?
    smart_listing_create(:packing_lists, packing_lists_scope, partial: 'packing_lists/listing', default_sort: {number: "asc"})
  end

  # GET /packing_lists/1
  # GET /packing_lists/1.json
  def show
  end

  # GET /packing_lists/new
  def new
    @packing_list = PackingList.new
  end

  # GET /packing_lists/1/edit
  def edit
  end

  # POST /packing_lists
  # POST /packing_lists.json
  def create
    add_additional_params_to_child
    @packing_list = PackingList.new(packing_list_params)
    recreate = false
    recreate_counter = 1
    begin
      begin
        recreate = false
        if @invalid = !@packing_list.save
          if @packing_list.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@packing_list.errors[:base].join("<br/>")}\",size: 'small'});"
          else
            @courier_unit = CourierUnit.select(:name).find(@packing_list.courier_unit_id) if @packing_list.courier_unit_id.present?
          end
        end
      rescue ActiveRecord::RecordNotUnique => e
        if recreate_counter < 5
          recreate = true
          recreate_counter += 1
        else
          recreate = false
          render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
        end
      end
    end while recreate
  end

  # PATCH/PUT /packing_lists/1
  # PATCH/PUT /packing_lists/1.json
  def update
    respond_to do |format|
      if @packing_list.update(packing_list_params)
        format.html { redirect_to @packing_list, notice: 'Packing list was successfully updated.' }
        format.json { render :show, status: :ok, location: @packing_list }
      else
        format.html { render :edit }
        format.json { render json: @packing_list.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /packing_lists/1
  # DELETE /packing_lists/1.json
  def destroy
    unless @packing_list.destroy
      @deleted = false
    else
      @deleted = true
    end
  end
  
  def get_courier_ways
    @courier_ways = CourierWay.select(:id, :name).where(courier_id: params[:courier_id]).order(:name)
  end

  def get_courier_units
    @courier_units = CourierUnit.select(:id, :name).where(courier_way_id: params[:courier_way_id]).order(:name)
  end
  
  def get_courier_price_types
    @courier_price_types = CourierPrice.select(:price_type).where(courier_unit_id: params[:courier_unit_id], city_id: params[:city_id]).order(:price_type).distinct
  end

  def get_courier_cities
    @courier_cities = City.joins(:courier_prices).select(:id, :name).where(["courier_prices.courier_unit_id = ?", params[:courier_unit_id]]).order(:name).distinct
  end
  
  def generate_packing_list_item_form
    @courier_unit = CourierUnit.select(:name).find(params[:courier_unit_id])
    packing_list = PackingList.new
    shipments = Shipment.select(:id, :delivery_order_number, :delivery_date, :quantity).select("cities.name").joins(order_booking: [destination_warehouse: :city]).where(delivery_order_number: params[:shipment_numbers], is_packed_up: false)
    @packing_list_items = []
    shipments.each do |shipment|
      @packing_list_items << packing_list.packing_list_items.build(shipment_id: shipment.id, attr_quantity: shipment.quantity, attr_do_number: shipment.delivery_order_number, attr_delivery_date: shipment.delivery_date.strftime("%d/%m/%Y"))
    end
  end
  
  def print
    
  end
  
  def autocomplete_shipment_number
    shipments = Shipment.select(:id, :delivery_order_number).where(is_packed_up: false).where("LOWER(delivery_order_number) LIKE LOWER('#{params[:term]}%')").order(:delivery_order_number)
    render json: shipments.map { |shipment|
      {
        id:    shipment.id,
        label: shipment.delivery_order_number
      }
    }
  end

  private
  
  def add_additional_params_to_child
    params[:packing_list][:packing_list_items_attributes].each do |key, value|
      params[:packing_list][:packing_list_items_attributes][key].merge! attr_courier_id: params[:packing_list][:attr_courier_id], attr_city_id: params[:packing_list][:attr_city_id], attr_packing_list_date: params[:packing_list][:departure_date], attr_courier_unit_id: params[:packing_list][:courier_unit_id]
    end if params[:packing_list][:packing_list_items_attributes].present?
  end
  
  # Use callbacks to share common setup or constraints between actions.
  def set_packing_list
    @packing_list = PackingList.
      select(:id, :number, :departure_date, :total_quantity, :total_volume, :total_weight, :status, :courier_unit_id).
      select("couriers.code AS courier_code", "couriers.name AS courier_name").
      select("courier_ways.name AS courier_way_name").
      select("courier_units.name AS courier_unit_name").
      select("cities.name AS city_name").
      select("courier_prices.price_type").
      joins(courier_unit: [courier_way: :courier]).
      joins("LEFT JOIN courier_prices ON packing_lists.courier_price_id = courier_prices.id").
      joins("LEFT JOIN cities ON courier_prices.city_id = cities.id").
      find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def packing_list_params
    params.require(:packing_list).permit(:courier_unit_id, :departure_date, :attr_courier_id, :attr_courier_price_type, :attr_courier_way_id, :attr_city_id,
      packing_list_items_attributes: [:shipment_id, :volume, :weight, :_destroy, :attr_delivery_date, :attr_do_number, :attr_quantity, :attr_courier_id, :attr_city_id, :attr_packing_list_date, :attr_courier_unit_id])
  end
end
