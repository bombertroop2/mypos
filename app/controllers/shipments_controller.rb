include SmartListing::Helper::ControllerExtensions
class ShipmentsController < ApplicationController
  load_and_authorize_resource except: :create
  helper SmartListing::Helper
  before_action :set_shipment, only: [:show, :edit, :update, :destroy]
  before_action :add_additional_params, only: :create  

  # GET /shipments
  # GET /shipments.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    if params[:filter_delivery_date].present?
      splitted_delivery_date_range = params[:filter_delivery_date].split("-")
      start_delivery_date = splitted_delivery_date_range[0].strip.to_date
      end_delivery_date = splitted_delivery_date_range[1].strip.to_date
    end
    if params[:filter_received_date].present?
      splitted_received_date_range = params[:filter_received_date].split("-")
      start_received_date = splitted_received_date_range[0].strip.to_date
      end_received_date = splitted_received_date_range[1].strip.to_date
    end
    shipments_scope = Shipment.select(:id, :delivery_order_number, :delivery_date, :received_date, :quantity).joins(:order_booking)
    shipments_scope = shipments_scope.where(["delivery_order_number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(shipments_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    shipments_scope = shipments_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    shipments_scope = shipments_scope.where(["DATE(received_date) BETWEEN ? AND ?", start_received_date, end_received_date]) if params[:filter_received_date].present?
    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @shipments = smart_listing_create(:shipments, shipments_scope, partial: 'shipments/listing', default_sort: {delivery_order_number: "asc"})
  end

  # GET /shipments/1
  # GET /shipments/1.json
  def show
  end

  # GET /shipments/new
  def new
    @shipment = Shipment.new
  end

  # GET /shipments/1/edit
  def edit
  end

  # POST /shipments
  # POST /shipments.json
  def create
    @invalid = false
    ActiveRecord::Base.transaction do
      @shipments = []
      params[:shipments].each do |shipment_index|
        begin
          shipment = Shipment.new(shipment_params(params[:shipments][shipment_index]))
          authorize! :manage, shipment
          unless shipment.save
            if shipment.errors[:base].present?
              render js: "bootbox.alert({message: \"#{shipment.errors[:base].join("<br/>")}\",size: 'small'});"
              raise ActiveRecord::Rollback
            elsif shipment.errors[:"shipment_products.base"].present?
              render js: "bootbox.alert({message: \"#{shipment.errors[:"shipment_products.base"].join("<br/>")}\",size: 'small'});"
              raise ActiveRecord::Rollback
            elsif shipment.errors[:"shipment_products.shipment_product_items.base"].present?
              render js: "bootbox.alert({message: \"#{shipment.errors[:"shipment_products.shipment_product_items.base"].join("<br/>")}\",size: 'small'});"
              raise ActiveRecord::Rollback
            else
              if params[:shipments][shipment_index][:order_booking_id].present?
                order_booking = OrderBooking.printed.where(id: params[:shipments][shipment_index][:order_booking_id]).select(:id).first
                order_booking.order_booking_products.select(:id).each do |order_booking_product|
                  shipment_product = shipment.shipment_products.select{|sp| sp.order_booking_product_id == order_booking_product.id}.first
                  shipment_product = shipment.shipment_products.build order_booking_product_id: order_booking_product.id if shipment_product.blank?
                  order_booking_product.order_booking_product_items.select(:id).each do |order_booking_product_item|
                    shipment_product.shipment_product_items.build order_booking_product_item_id: order_booking_product_item.id if shipment_product.shipment_product_items.select{|spi| spi.order_booking_product_item_id == order_booking_product_item.id}.blank?
                  end
                end if order_booking.present?
              end
              @invalid = true
            end
          else
            shipment.delivery_date = shipment.delivery_date.strftime("%d/%m/%Y")
          end
          @shipments << shipment
        rescue ActiveRecord::RecordNotUnique => e
          render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
          raise ActiveRecord::Rollback
        end
      end
      raise ActiveRecord::Rollback if @invalid
    end
  end

  # PATCH/PUT /shipments/1
  # PATCH/PUT /shipments/1.json
  def update
    respond_to do |format|
      if @shipment.update(shipment_params)
        format.html { redirect_to @shipment, notice: 'Shipment was successfully updated.' }
        format.json { render :show, status: :ok, location: @shipment }
      else
        format.html { render :edit }
        format.json { render json: @shipment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shipments/1
  # DELETE /shipments/1.json
  def destroy
    unless @shipment.destroy
      @deleted = false
    else
      @deleted = true
    end  
  end
  
  def generate_ob_detail
    order_booking_ids = params[:order_booking_ids].split(",")
    order_booking_numbers = params[:order_booking_numbers].split(",")
    order_bookings = OrderBooking.printed.where(id: order_booking_ids).select(:id, :number).order(:number)
    unavailable_obs = []
    order_booking_ids.each_with_index do |order_booking_id, index|
      if order_bookings.select{|order_booking| order_booking.id == order_booking_id.to_i}.blank?
        unavailable_obs << order_booking_numbers[index]
      end
    end
    if unavailable_obs.length == 1
      render js: "bootbox.alert({message: \"Order booking #{unavailable_obs.to_sentence} is not available\",size: 'small'});"
    elsif unavailable_obs.length > 1
      render js: "bootbox.alert({message: \"Order booking #{unavailable_obs.to_sentence} are not available\"});"
    else
      @shipments = []
      order_bookings.each do |order_booking|
        shipment = Shipment.new order_booking_id: order_booking.id, order_booking_number: order_booking.number, delivery_date: params[:delivery_date], courier_id: params[:courier_id]
        order_booking.order_booking_products.select(:id).each do |order_booking_product|
          shipment_product = shipment.shipment_products.build order_booking_product_id: order_booking_product.id
          order_booking_product.order_booking_product_items.select(:id).each do |order_booking_product_item|
            shipment_product.shipment_product_items.build order_booking_product_item_id: order_booking_product_item.id
          end
        end
        @shipments << shipment
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_shipment
    @shipment = Shipment.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def shipment_params(params)
    params.permit(:order_booking_number, :quantity, :delivery_date, :order_booking_id, :courier_id,
      shipment_products_attributes: [:order_booking_product_id, :order_booking_id, :quantity,
        shipment_product_items_attributes: [:order_booking_product_item_id, :quantity,
          :order_booking_product_id, :order_booking_id]])
  end
  
  def add_additional_params
    params[:shipments].each do |shipments_key, shipments_value|
      total_quantity_shipment = 0
      params[:shipments][shipments_key][:shipment_products_attributes].each do |key, value|
        total_quantity_shipment_product = 0
        params[:shipments][shipments_key][:shipment_products_attributes][key].merge! order_booking_id: params[:shipments][shipments_key][:order_booking_id]
        params[:shipments][shipments_key][:shipment_products_attributes][key][:shipment_product_items_attributes].each do |spi_key, value|
          total_quantity_shipment += params[:shipments][shipments_key][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key][:quantity].to_i
          total_quantity_shipment_product += params[:shipments][shipments_key][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key][:quantity].to_i
          params[:shipments][shipments_key][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key].merge! order_booking_product_id: params[:shipments][shipments_key][:shipment_products_attributes][key][:order_booking_product_id], order_booking_id: params[:shipments][shipments_key][:order_booking_id]
        end if params[:shipments][shipments_key][:shipment_products_attributes][key][:shipment_product_items_attributes].present?
        params[:shipments][shipments_key][:shipment_products_attributes][key].merge! quantity: total_quantity_shipment_product
      end if params[:shipments][shipments_key][:shipment_products_attributes].present?
      params[:shipments][shipments_key].merge! quantity: total_quantity_shipment
    end
  end
end
