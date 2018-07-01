class Api::ShipmentsController < Api::ApplicationController
  before_action :authenticate_user!
  authorize_resource
  before_action :set_delivery_order, only: :receive

  # GET /shipments
  # GET /shipments.json
  def inventory_receipts
    #    @delivery_orders = if current_user.has_non_spg_role?
    #      Shipment.select(:id, :delivery_order_number, :delivery_date, :received_date, :quantity, :is_receive_date_changed).joins(:order_booking).where("received_date IS NULL")
    #    else
    #      Shipment.select(:id, :delivery_order_number, :delivery_date, :received_date, :quantity, :is_receive_date_changed).joins(:order_booking).where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id} AND received_date IS NULL")
    #    end
    @delivery_orders = Shipment.select(:id, :delivery_order_number, :delivery_date, :received_date, :quantity, :is_receive_date_changed).joins(:order_booking).where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id} AND received_date IS NULL")
  end
    
  def receive
    received = false
    @delivery_order.with_lock do
      received = @delivery_order.update(received_date: params[:receive_date], receiving_inventory: true)
    end
    unless received
      if @delivery_order.errors[:base].present?
        render json: { status: false, message: @delivery_order.errors[:base].first }, status: :unprocessable_entity
      elsif @delivery_order.errors[:received_date].present?
        render json: { status: false, message: "Receive date #{@delivery_order.errors[:received_date].first}" }, status: :unprocessable_entity
      end
    else
      render json: { status: true, message: "Delivery order #{@delivery_order.delivery_order_number} was successfully received" }
    end
  end
  
  def search_do
    #    @delivery_orders = if current_user.has_non_spg_role?
    #      Shipment.select(:id).joins(:order_booking).where(["(shipments.delivery_order_number = ? OR order_bookings.number = ?) AND received_date IS NULL", params[:do_ob_number], params[:do_ob_number]])
    #    else
    #      Shipment.select(:id).joins(:order_booking).where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").where(["(shipments.delivery_order_number = ? OR order_bookings.number = ?) AND received_date IS NULL", params[:do_ob_number], params[:do_ob_number]])
    #    end
    @delivery_orders = Shipment.select(:id).joins(:order_booking).where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").where(["(shipments.delivery_order_number = ? OR order_bookings.number = ?) AND received_date IS NULL", params[:do_ob_number], params[:do_ob_number]])
    
    # apabila jumlahnya lebih dari satu maka artinya satu DO bisa banyak OB, jadi tidak bisa search by OB number (tapi sekarang 1 DO = 1 OB)
    if @delivery_orders.length == 0 || @delivery_orders.length > 1
      render json: { status: false, message: "No records found" }, status: :unprocessable_entity
    else
      render json: { status: true, delivery_order: @delivery_orders.first }
    end
  end
    
  private
    
  def set_delivery_order
    #    @delivery_order = if current_user.has_non_spg_role?
    #      Shipment.find(params[:id])
    #    else
    #      Shipment.joins(:order_booking).where(id: params[:id]).
    #        where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
    #        select("shipments.*").first
    #    end
    @delivery_order = Shipment.joins(:order_booking).where(id: params[:id]).
      where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
      select("shipments.*").first
  end

  
end
