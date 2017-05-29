include SmartListing::Helper::ControllerExtensions
class ShipmentsController < ApplicationController
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
    if params[:filter_plan_date].present?
      splitted_date_range = params[:filter_plan_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end
    shipments_scope = Shipment.select(:id, :delivery_order_number, :delivery_date, :received_date, :quantity)
    shipments_scope = shipments_scope.where(["delivery_order_number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(shipments_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    shipments_scope = shipments_scope.where(["DATE(plan_date) BETWEEN ? AND ?", start_date, end_date]) if params[:filter_plan_date].present?
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
    begin
      @shipment = Shipment.new(shipment_params)
      unless @shipment.save
        @invalid = true
        if params[:shipment][:order_booking_id].present?
          @order_booking = OrderBooking.printed.where(id: params[:shipment][:order_booking_id]).select(:id).first
          @order_booking.order_booking_products.select(:id).each do |order_booking_product|
            shipment_product = @shipment.shipment_products.select{|sp| sp.order_booking_product_id == order_booking_product.id}.first
            shipment_product = @shipment.shipment_products.build order_booking_product_id: order_booking_product.id if shipment_product.blank?
            order_booking_product.order_booking_product_items.select(:id).each do |order_booking_product_item|
              shipment_product.shipment_product_items.build order_booking_product_item_id: order_booking_product_item.id if shipment_product.shipment_product_items.select{|spi| spi.order_booking_product_item_id == order_booking_product_item.id}.blank?
            end
          end if @order_booking.present?
        end
      end
    rescue ActiveRecord::RecordNotUnique => e
      render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
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
    @shipment.destroy
    respond_to do |format|
      format.html { redirect_to shipments_url, notice: 'Shipment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def generate_ob_detail
    order_booking = OrderBooking.printed.where(id: params[:order_booking_id]).select(:id).first
    if order_booking.present?
      @shipment = Shipment.new
      order_booking.order_booking_products.select(:id).each do |order_booking_product|
        shipment_product = @shipment.shipment_products.build order_booking_product_id: order_booking_product.id
        order_booking_product.order_booking_product_items.select(:id).each do |order_booking_product_item|
          shipment_product.shipment_product_items.build order_booking_product_item_id: order_booking_product_item.id
        end
      end
    else
      @shipment = nil
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_shipment
    @shipment = Shipment.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def shipment_params
    params.require(:shipment).permit(:quantity, :delivery_date, :order_booking_id, :courier_id,
      shipment_products_attributes: [:order_booking_product_id, :order_booking_id, :quantity,
        shipment_product_items_attributes: [:order_booking_product_item_id, :quantity,
          :order_booking_product_id, :order_booking_id]]).merge(created_by: current_user.id)
  end
  
  def add_additional_params
    total_quantity_shipment = 0
    params[:shipment][:shipment_products_attributes].each do |key, value|
      total_quantity_shipment_product = 0
      params[:shipment][:shipment_products_attributes][key].merge! order_booking_id: params[:shipment][:order_booking_id]
      params[:shipment][:shipment_products_attributes][key][:shipment_product_items_attributes].each do |spi_key, value|
        total_quantity_shipment += params[:shipment][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key][:quantity].to_i
        total_quantity_shipment_product += params[:shipment][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key][:quantity].to_i
        params[:shipment][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key].merge! order_booking_product_id: params[:shipment][:shipment_products_attributes][key][:order_booking_product_id], order_booking_id: params[:shipment][:order_booking_id]
      end if params[:shipment][:shipment_products_attributes][key][:shipment_product_items_attributes].present?
      params[:shipment][:shipment_products_attributes][key].merge! quantity: total_quantity_shipment_product
    end if params[:shipment][:shipment_products_attributes].present?
    params[:shipment].merge! quantity: total_quantity_shipment
  end
end
