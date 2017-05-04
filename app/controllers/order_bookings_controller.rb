include SmartListing::Helper::ControllerExtensions
class OrderBookingsController < ApplicationController
  before_action :set_order_booking, only: [:show, :edit, :update, :destroy]
  before_action :populate_warehouses, only: :new
  helper SmartListing::Helper

  # GET /order_bookings
  # GET /order_bookings.json
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
    order_bookings_scope = OrderBooking.select(:id, :number, :plan_date, :quantity, :status).
      select("ow.name AS ow_name, dw.name AS dw_name").
      joins("INNER JOIN warehouses ow ON ow.id = order_bookings.origin_warehouse_id").
      joins("INNER JOIN warehouses dw ON dw.id = order_bookings.destination_warehouse_id")
    order_bookings_scope = order_bookings_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(order_bookings_scope.where(["ow.name #{like_command} ?", "%"+params[:filter_string]+"%"])).
      or(order_bookings_scope.where(["dw.name #{like_command} ?", "%"+params[:filter_string]+"%"])).
      or(order_bookings_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    order_bookings_scope = order_bookings_scope.where(["DATE(plan_date) BETWEEN ? AND ?", start_date, end_date]) if params[:filter_plan_date].present?
    order_bookings_scope = order_bookings_scope.where(["status = ?", params[:filter_status]]) if params[:filter_status].present?
    @order_bookings = smart_listing_create(:order_bookings, order_bookings_scope, partial: 'order_bookings/listing', default_sort: {number: "asc"})
  end

  # GET /order_bookings/1
  # GET /order_bookings/1.json
  def show
  end

  # GET /order_bookings/new
  def new
    @order_booking = OrderBooking.new
  end

  # GET /order_bookings/1/edit
  def edit
  end

  # POST /order_bookings
  # POST /order_bookings.json
  def create
    add_additional_params_to_child
    @order_booking = OrderBooking.new(order_booking_params)
    unless @order_booking.save
      populate_warehouses
      if @order_booking.errors[:base].present?
        render js: "bootbox.alert({message: \"#{@order_booking.errors[:base].join("<br/>")}\",size: 'small'});"
      elsif @order_booking.errors[:"order_booking_products.base"].present?
        render js: "bootbox.alert({message: \"#{@order_booking.errors[:"order_booking_products.base"].join("<br/>")}\",size: 'small'});"
      else
        stock = Stock.select(:id).where(warehouse_id: @order_booking.origin_warehouse_id).first
        @products = stock.stock_products.joins(product: :brand).select("products.id, products.code, common_fields.name") if stock.present?
        @selected_products = Product.joins(stock_products: :stock).
          where(id: @order_booking.order_booking_products.map(&:product_id)).
          where(["stocks.warehouse_id = ?", @order_booking.origin_warehouse_id]).
          select(:id)
      end
    else
      @ori_warehouse_name = Warehouse.select(:name).where(id: @order_booking.origin_warehouse_id).first.name
      @dest_warehouse_name = Warehouse.select(:name).where(id: @order_booking.destination_warehouse_id).first.name
    end
  rescue ActiveRecord::RecordNotUnique => e
    render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
  end

  # PATCH/PUT /order_bookings/1
  # PATCH/PUT /order_bookings/1.json
  def update
    respond_to do |format|
      if @order_booking.update(order_booking_params)
        format.html { redirect_to @order_booking, notice: 'Order booking was successfully updated.' }
        format.json { render :show, status: :ok, location: @order_booking }
      else
        format.html { render :edit }
        format.json { render json: @order_booking.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /order_bookings/1
  # DELETE /order_bookings/1.json
  def destroy
    @order_booking.destroy
    respond_to do |format|
      format.html { redirect_to order_bookings_url, notice: 'Order booking was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def get_warehouse_products
    @stock = Stock.select(:id).where(warehouse_id: params[:origin_warehouse_id]).first
    @products = @stock.stock_products.joins(product: :brand).select("products.id, products.code, common_fields.name") if @stock.present?
  end
  
  def generate_product_item_form
    selected_product_ids = params[:product_ids].split(",")
    @order_booking = OrderBooking.new
    @selected_products = Product.joins(stock_products: :stock).joins(:brand).
      where(id: selected_product_ids).
      where(["stocks.warehouse_id = ?", params[:origin_warehouse_id]]).
      select("products.id, products.code, stock_products.id AS stock_product_id, common_fields.name AS brand_name")
    @selected_products.each do |product|
      obp = @order_booking.order_booking_products.build product_id: product.id, product_code: product.code, product_name: product.brand_name
      stock_product = StockProduct.where(id: product.stock_product_id).select(:id).first
      stock_product.stock_details.select("size_id, color_id").each do |stock_detail|
        obp.order_booking_product_items.build size_id: stock_detail.size_id, color_id: stock_detail.color_id
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_order_booking
    @order_booking = OrderBooking.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def order_booking_params
    params.require(:order_booking).permit(:plan_date, :origin_warehouse_id,
      :destination_warehouse_id, :note, order_booking_products_attributes: [:product_id,
        :product_code, :product_name, :origin_warehouse_id,
        order_booking_product_items_attributes: [:size_id, :color_id, :quantity,
          :product_id, :origin_warehouse_id]]).merge(created_by: current_user.id)
  end
  
  def populate_warehouses
    @origin_warehouses = Warehouse.central.select(:id, :code)
    @destination_warehouses = Warehouse.not_central.select(:id, :code)
  end
  
  def add_additional_params_to_child
    params[:order_booking][:order_booking_products_attributes].each do |key, value|
      product_id = params[:order_booking][:order_booking_products_attributes][key][:product_id]
      params[:order_booking][:order_booking_products_attributes][key].merge! origin_warehouse_id: params[:order_booking][:origin_warehouse_id]
      params[:order_booking][:order_booking_products_attributes][key][:order_booking_product_items_attributes].each do |obpi_key, value|
        params[:order_booking][:order_booking_products_attributes][key][:order_booking_product_items_attributes][obpi_key].merge! product_id: product_id, origin_warehouse_id: params[:order_booking][:origin_warehouse_id]
      end if params[:order_booking][:order_booking_products_attributes][key][:order_booking_product_items_attributes].present?
    end if params[:order_booking][:order_booking_products_attributes].present?
  end
end
