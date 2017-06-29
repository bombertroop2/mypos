include SmartListing::Helper::ControllerExtensions
class ShipmentReceiptsController < ApplicationController
  helper SmartListing::Helper
  load_and_authorize_resource
  before_action :set_shipment_receipt, only: :show

  # GET /shipment_receipts
  # GET /shipment_receipts.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    if params[:filter_received_date].present?
      splitted_received_date_range = params[:filter_received_date].split("-")
      start_received_date = splitted_received_date_range[0].strip.to_date
      end_received_date = splitted_received_date_range[1].strip.to_date
    end
    shipment_receipts_scope = if current_user.has_non_spg_role?
      ShipmentReceipt.joins(:shipment).select(:id, :received_date, :quantity).select(:delivery_order_number)
    else
      ShipmentReceipt.joins(shipment: :order_booking).select(:id, :received_date, :quantity).select(:delivery_order_number).where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}")
    end
    shipment_receipts_scope = shipment_receipts_scope.where(["shipment_receipts.quantity #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(shipment_receipts_scope.where(["delivery_order_number #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string]
    shipment_receipts_scope = shipment_receipts_scope.where(["DATE(shipment_receipts.received_date) BETWEEN ? AND ?", start_received_date, end_received_date]) if params[:filter_received_date].present?
    @shipment_receipts = smart_listing_create(:shipment_receipts, shipment_receipts_scope, partial: 'shipment_receipts/listing', default_sort: {delivery_order_number: "asc"})
  end

  # GET /shipment_receipts/1
  # GET /shipment_receipts/1.json
  def show
  end

  # GET /shipment_receipts/new
  def new
    @in_transit_shipments = if current_user.has_non_spg_role?
      Shipment.select(:delivery_order_number, :number).
        select("shipments.id").joins(:order_booking).where("received_date IS NULL")
    else
      Shipment.select(:delivery_order_number, :number).
        select("shipments.id").joins(:order_booking).where("received_date IS NULL AND order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}")
    end
  end

  # POST /shipment_receipts
  # POST /shipment_receipts.json
  def create
    add_additional_params
    @saved = false
    @shipment_receipt = ShipmentReceipt.new(shipment_receipt_params)
    @shipment_receipt.creator = current_user
    if @shipment_receipt.save
      @saved = true
      @do_number = Shipment.select(:delivery_order_number).where(id: @shipment_receipt.shipment_id).first.delivery_order_number
    end
  rescue ActiveRecord::RecordNotUnique => e
    render js: "bootbox.alert({message: \"Sorry, shipment #{@shipment_receipt.shipment.delivery_order_number} has already been received\",size: 'small'});"
  end
  
  def generate_form
    shipment = if current_user.has_non_spg_role?
      Shipment.joins(:order_booking).where(id: params[:shipment_id]).
        where("received_date IS NULL").select(:id, :delivery_order_number, :number).first
    else
      Shipment.joins(:order_booking).where(id: params[:shipment_id]).
        where("received_date IS NULL AND order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").select(:id, :delivery_order_number, :number).first
    end
    if shipment.present?
      @shipment_receipt = ShipmentReceipt.new shipment_id: shipment.id, do_number: shipment.delivery_order_number, ob_number: shipment.number
      shipment.shipment_products.select(:id).each do |shipment_product|
        shipment_receipt_product = @shipment_receipt.shipment_receipt_products.build shipment_product_id: shipment_product.id
        shipment_product.shipment_product_items.select(:id).each do |shipment_product_item|
          shipment_receipt_product.shipment_receipt_product_items.build shipment_product_item_id: shipment_product_item.id
        end
      end
    else
      render js: "bootbox.alert({message: \"Selected shipment is not available\",size: 'small'});"
    end
  end
  
  private
  
  # Use callbacks to share common setup or constraints between actions.
  def set_shipment_receipt
    @shipment_receipt = if current_user.has_non_spg_role?
      ShipmentReceipt.select("shipment_receipts.*").where(id: params[:id]).first
    else
      ShipmentReceipt.select("shipment_receipts.*").where(id: params[:id]).joins(shipment: :order_booking).where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").first
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def shipment_receipt_params
    params.require(:shipment_receipt).permit(:do_number, :ob_number, :received_date,
      :shipment_id, shipment_receipt_products_attributes: [:shipment_id, :shipment_product_id,
        shipment_receipt_product_items_attributes: [:shipment_product_item_id, :shipment_id, :shipment_product_id]])
  end
  
  def add_additional_params
    params[:shipment_receipt][:shipment_receipt_products_attributes].each do |key, value|
      params[:shipment_receipt][:shipment_receipt_products_attributes][key].merge! shipment_id: params[:shipment_receipt][:shipment_id]
      params[:shipment_receipt][:shipment_receipt_products_attributes][key][:shipment_receipt_product_items_attributes].each do |srpi_key, srpi_value|
        params[:shipment_receipt][:shipment_receipt_products_attributes][key][:shipment_receipt_product_items_attributes][srpi_key].merge! shipment_id: params[:shipment_receipt][:shipment_id], shipment_product_id: params[:shipment_receipt][:shipment_receipt_products_attributes][key][:shipment_product_id]
      end if params[:shipment_receipt][:shipment_receipt_products_attributes][key][:shipment_receipt_product_items_attributes].present?
    end if params[:shipment_receipt][:shipment_receipt_products_attributes].present?
  end
end
