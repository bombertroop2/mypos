include SmartListing::Helper::ControllerExtensions
class OrderBookingsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_order_booking, only: [:show, :edit, :update, :destroy, :picking_note]
  before_action :populate_warehouses, only: [:new, :edit]
  before_action :add_additional_params_to_child, only: [:create, :update]

  # GET /order_bookings
  # GET /order_bookings.json
  def index
    like_command = "ILIKE"
    if params[:filter_plan_date].present?
      splitted_date_range = params[:filter_plan_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end
    order_bookings_scope = if current_user.has_non_spg_role?
      OrderBooking.select(:id, :number, :plan_date, :quantity, :status).
        select("ow.name AS ow_name, dw.name AS dw_name").
        joins("INNER JOIN warehouses ow ON ow.id = order_bookings.origin_warehouse_id").
        joins("INNER JOIN warehouses dw ON dw.id = order_bookings.destination_warehouse_id")
    else
      OrderBooking.select(:id, :number, :plan_date, :quantity, :status).
        select("ow.name AS ow_name, dw.name AS dw_name").
        joins("INNER JOIN warehouses ow ON ow.id = order_bookings.origin_warehouse_id").
        joins("INNER JOIN warehouses dw ON dw.id = order_bookings.destination_warehouse_id").
        where(destination_warehouse_id: current_user.sales_promotion_girl.warehouse_id)
    end
    order_bookings_scope = order_bookings_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(order_bookings_scope.where(["ow.name #{like_command} ?", "%"+params[:filter_string]+"%"])).
      or(order_bookings_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    order_bookings_scope = order_bookings_scope.where(["DATE(plan_date) BETWEEN ? AND ?", start_date, end_date]) if params[:filter_plan_date].present?
    order_bookings_scope = order_bookings_scope.where(["status = ?", params[:filter_status]]) if params[:filter_status].present?
    order_bookings_scope = order_bookings_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
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
    @order_booking.plan_date = @order_booking.plan_date.strftime("%d/%m/%Y")
    stock = Stock.select(:id).where(warehouse_id: @order_booking.origin_warehouse_id).first
    @products = stock.stock_products.joins([product: :brand], :stock_details).
      select("products.id, products.code, common_fields.name, SUM(quantity - booked_quantity) AS total_afs").
      group("products.id, common_fields.name") if stock.present?
    @selected_products = Product.joins([stock_products: :stock], :brand).
      where(id: @order_booking.order_booking_products.pluck(:product_id)).
      where(["stocks.warehouse_id = ?", @order_booking.origin_warehouse_id]).
      select(:id).select("products.code, common_fields.name AS brand_name").
      select("stock_products.id AS stock_product_id")
    @order_booking_products = []
    @order_booking.order_booking_products.each do |order_booking_product|
      selected_product = @selected_products.select{|slctd_prdct| slctd_prdct.id == order_booking_product.product_id}.first
      StockDetail.where(stock_product_id: selected_product.stock_product_id).select("size_id, color_id, quantity, booked_quantity").each do |stock_detail|
        afs_quantity = stock_detail.quantity - stock_detail.booked_quantity
        order_booking_product.order_booking_product_items.build size_id: stock_detail.size_id, color_id: stock_detail.color_id, available_for_booking_quantity: afs_quantity if order_booking_product.order_booking_product_items.select{|obpi| obpi.size_id == stock_detail.size_id && obpi.color_id == stock_detail.color_id}.blank?
      end
      @order_booking_products << order_booking_product
    end
  end

  # POST /order_bookings
  # POST /order_bookings.json
  def create
    @order_bookings = []
    @ori_warehouse_names = []
    @dest_warehouse_names = []
    warehouse_to_and_customer_ids = params[:warehouse_to_ids].split(",")
    ActiveRecord::Base.transaction do
      warehouse_to_and_customer_ids.each do |warehouse_to_and_customer_id|
        warehouse_to_id = warehouse_to_and_customer_id.split(":")[0]
        customer_id = warehouse_to_and_customer_id.split(":")[1] rescue nil
        begin
          @order_booking = OrderBooking.new(order_booking_params)
          @order_booking.order_booking_products.each do |obp|
            obp.attr_destination_warehouse_id = warehouse_to_id
          end
          @order_booking.destination_warehouse_id = warehouse_to_id
          @order_booking.customer_id = customer_id
          unless @order_booking.save
            if @order_booking.errors[:base].present?
              render js: "bootbox.alert({message: \"#{@order_booking.errors[:base].join("<br/>")}\",size: 'small'});"
            elsif @order_booking.errors[:"order_booking_products.base"].present?
              render js: "bootbox.alert({message: \"#{@order_booking.errors[:"order_booking_products.base"].join("<br/>")}\",size: 'small'});"
            else
              @customers = Customer.select(:id, :code, :name).order(:code)
              populate_warehouses
              stock = Stock.select(:id).where(warehouse_id: @order_booking.origin_warehouse_id).first
              @products = stock.stock_products.joins([product: :brand], :stock_details).
                select("products.id, products.code, common_fields.name, SUM(quantity - booked_quantity) AS total_afs").
                group("products.id, common_fields.name") if stock.present?
              @selected_products = Product.joins(stock_products: :stock).
                where(id: @order_booking.order_booking_products.map(&:product_id)).
                where(["stocks.warehouse_id = ?", @order_booking.origin_warehouse_id]).
                select(:id).select("stock_products.id AS stock_product_id")
              @order_booking_products = []
              @order_booking.order_booking_products.each do |order_booking_product|
                selected_product = @selected_products.select{|slctd_prdct| slctd_prdct.id == order_booking_product.product_id}.first
                StockDetail.where(stock_product_id: selected_product.stock_product_id).select("size_id, color_id, quantity, booked_quantity").each do |stock_detail|
                  afs_quantity = stock_detail.quantity - stock_detail.booked_quantity
                  order_booking_product.order_booking_product_items.build size_id: stock_detail.size_id, color_id: stock_detail.color_id, available_for_booking_quantity: afs_quantity if order_booking_product.order_booking_product_items.select{|obpi| obpi.size_id == stock_detail.size_id && obpi.color_id == stock_detail.color_id}.blank?
                end
                @order_booking_products << order_booking_product
              end
              @invalid = true
            end
            raise ActiveRecord::Rollback
          else
            @ori_warehouse_names << Warehouse.select(:name).where(id: @order_booking.origin_warehouse_id).first.name
            @dest_warehouse_names << Warehouse.select(:name).where(id: @order_booking.destination_warehouse_id).first.name
            @order_bookings << @order_booking
          end
        rescue ActiveRecord::RecordNotUnique => e
          render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  # PATCH/PUT /order_bookings/1
  # PATCH/PUT /order_bookings/1.json
  def update
    if @total_products != 0 && @total_deleted_products != 0 && @total_products == @total_deleted_products
      render js: "bootbox.alert({message: \"Sorry, you can't delete all records\",size: 'small'});"
    else
      params[:order_booking][:order_booking_products_attributes].each do |key, value|
        params[:order_booking][:order_booking_products_attributes][key].merge! attr_destination_warehouse_id: @order_booking.destination_warehouse_id
      end if params[:order_booking][:order_booking_products_attributes].present?
      unless @order_booking.update(order_booking_params)
        if @order_booking.errors[:base].present?
          render js: "bootbox.alert({message: \"#{@order_booking.errors[:base].join("<br/>")}\",size: 'small'});"
        elsif @order_booking.errors[:"order_booking_products.base"].present?
          render js: "bootbox.alert({message: \"#{@order_booking.errors[:"order_booking_products.base"].join("<br/>")}\",size: 'small'});"
        else
          populate_warehouses
          stock = Stock.select(:id).where(warehouse_id: @order_booking.origin_warehouse_id).first
          @products = stock.stock_products.joins([product: :brand], :stock_details).
            select("products.id, products.code, common_fields.name, SUM(quantity - booked_quantity) AS total_afs").
            group("products.id, common_fields.name") if stock.present?
          selected_product_ids = []
          params[:order_booking][:order_booking_products_attributes].each do |key, value|
            selected_product_ids << params[:order_booking][:order_booking_products_attributes][key][:product_id]
          end if params[:order_booking][:order_booking_products_attributes].present?
          @selected_products = Product.joins(stock_products: :stock).
            where(id: selected_product_ids).
            where(["stocks.warehouse_id = ?", @order_booking.origin_warehouse_id]).
            select(:id).select("stock_products.id AS stock_product_id")
          @order_booking_products = []
          @order_booking.order_booking_products.each do |order_booking_product|
            selected_product = @selected_products.select{|slctd_prdct| slctd_prdct.id == order_booking_product.product_id}.first
            if selected_product.present?
              StockDetail.where(stock_product_id: selected_product.stock_product_id).select("size_id, color_id, quantity, booked_quantity").each do |stock_detail|
                afs_quantity = stock_detail.quantity - stock_detail.booked_quantity
                order_booking_product.order_booking_product_items.build size_id: stock_detail.size_id, color_id: stock_detail.color_id, available_for_booking_quantity: afs_quantity, disable_validation: true if order_booking_product.order_booking_product_items.select{|obpi| obpi.size_id == stock_detail.size_id && obpi.color_id == stock_detail.color_id}.blank?
              end
              if @order_booking.origin_warehouse_id_changed? && order_booking_product.new_record?
                @order_booking_products << order_booking_product
              elsif !@order_booking.origin_warehouse_id_changed?
                @order_booking_products << order_booking_product
              end
            end
          end
          @invalid = true
        end
      else
        @ori_warehouse_name = Warehouse.select(:name).where(id: @order_booking.origin_warehouse_id).first.name
        #        @dest_warehouse_name = Warehouse.select(:name).where(id: @order_booking.destination_warehouse_id).first.name
      end
    end
  end

  # DELETE /order_bookings/1
  # DELETE /order_bookings/1.json
  def destroy
    @order_booking.destroy
    if @order_booking.errors.present? && @order_booking.errors.messages[:base].present?
      render js: "bootbox.alert({message: \"#{@order_booking.errors.messages[:base].join("<br/>")}\",size: 'small'});"
    end
  end
  
  def get_warehouse_products
    @stock = Stock.select(:id).where(warehouse_id: params[:origin_warehouse_id]).first
    @products = @stock.stock_products.joins([product: :brand], :stock_details).
      select("products.id, products.code, common_fields.name, SUM(quantity - booked_quantity) AS total_afs").
      group("products.id, common_fields.name") if @stock.present?
    @order_booking_id = params[:order_booking_id]
  end
  
  def generate_product_item_form
    @order_booking = if params[:order_booking_id].present?
      OrderBooking.select(:id, :origin_warehouse_id).where(id: params[:order_booking_id]).first
    else
      OrderBooking.new
    end
    
    @selected_products = if params[:prev_selected_product_ids].present?
      if params[:add_all_products].eql?("true")
        Product.joins(stock_products: :stock).joins(:brand).
          where(["stocks.warehouse_id = ?", params[:origin_warehouse_id]]).
          where(["products.id NOT IN (?)", params[:prev_selected_product_ids].split(",")]).
          select("products.id, products.code, stock_products.id AS stock_product_id, common_fields.name AS brand_name")
      else
        Product.joins(stock_products: :stock).joins(:brand).
          where(code: params[:product_code]).
          where(["stocks.warehouse_id = ?", params[:origin_warehouse_id]]).
          where(["products.id NOT IN (?)", params[:prev_selected_product_ids].split(",")]).
          select("products.id, products.code, stock_products.id AS stock_product_id, common_fields.name AS brand_name")
      end
    else
      if params[:add_all_products].eql?("true")
        Product.joins(stock_products: :stock).joins(:brand).
          where(["stocks.warehouse_id = ?", params[:origin_warehouse_id]]).
          select("products.id, products.code, stock_products.id AS stock_product_id, common_fields.name AS brand_name")
      else
        Product.joins(stock_products: :stock).joins(:brand).
          where(code: params[:product_code]).
          where(["stocks.warehouse_id = ?", params[:origin_warehouse_id]]).
          select("products.id, products.code, stock_products.id AS stock_product_id, common_fields.name AS brand_name")
      end
    end

    if @selected_products.present?
      @order_booking_products = []
      @selected_products.each do |product|
        if (obp = @order_booking.order_booking_products.select{|order_booking_product| order_booking_product.product_id == product.id}.first).blank?
          obp = @order_booking.order_booking_products.build product_id: product.id, product_code: product.code, product_name: product.brand_name
        elsif @order_booking.origin_warehouse_id == params[:origin_warehouse_id].to_i
          obp.product_code = product.code
          obp.product_name = product.brand_name
        else
          obp = @order_booking.order_booking_products.build product_id: product.id, product_code: product.code, product_name: product.brand_name
        end
        StockDetail.where(stock_product_id: product.stock_product_id).select("size_id, color_id, quantity, booked_quantity").each do |stock_detail|
          afs_quantity = stock_detail.quantity - stock_detail.booked_quantity
          obp.order_booking_product_items.build size_id: stock_detail.size_id, color_id: stock_detail.color_id, available_for_booking_quantity: afs_quantity if obp.order_booking_product_items.select{|obpi| obpi.size_id == stock_detail.size_id && obpi.color_id == stock_detail.color_id}.blank?
        end
        @order_booking_products << obp
      end
    else
      render js: "bootbox.alert({message: \"No records found or already added to the list\",size: 'small'});"
    end
  end
  
  def picking_note
    if @order_booking.update status: "P", print_date: Time.current, picking_note: true
      @ori_warehouse_name = Warehouse.select(:name).where(id: @order_booking.origin_warehouse_id).first.name
      @dest_warehouse_name = Warehouse.select(:name).where(id: @order_booking.destination_warehouse_id).first.name
    elsif @order_booking.errors.present? && @order_booking.errors.messages[:base].present?
      render js: "bootbox.alert({message: \"#{@order_booking.errors.messages[:base].join("<br/>")}\",size: 'small'});"
    end
  end
  
  def add_destination_warehouse
    @destination_warehouse = Warehouse.select(:id, :code, :name, :warehouse_type).not_central.not_in_transit.actived.where(code: params[:warehouse_code]).first
    if @destination_warehouse.blank?
      render js: "bootbox.alert({message: \"No records found\",size: 'small'});"
    else
      if @destination_warehouse.warehouse_type.eql?("direct_sales")
        @customers = Customer.select(:id, :code, :name).order(:code)
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_order_booking
    @order_booking = if current_user.has_non_spg_role?
      OrderBooking.find(params[:id])
    else
      OrderBooking.
        joins(:origin_warehouse).
        joins(:destination_warehouse).
        where(id: params[:id], destination_warehouse_id: current_user.sales_promotion_girl.warehouse_id).
        first
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def order_booking_params
    if action_name.eql?("create")
      params.require(:order_booking).permit(:plan_date, :origin_warehouse_id,
        :destination_warehouse_id, :note, order_booking_products_attributes: [:product_id,
          :product_code, :product_name, :origin_warehouse_id, :id, :_destroy,
          order_booking_product_items_attributes: [:new_product, :id, :size_id, :color_id, :quantity,
            :available_for_booking_quantity, :product_id, :origin_warehouse_id]])
    else
      params.require(:order_booking).permit(:plan_date, :origin_warehouse_id,
        :note, order_booking_products_attributes: [:product_id,
          :product_code, :product_name, :origin_warehouse_id, :id, :_destroy, :attr_destination_warehouse_id,
          order_booking_product_items_attributes: [:new_product, :id, :size_id, :color_id, :quantity,
            :available_for_booking_quantity, :product_id, :origin_warehouse_id]])
    end
  end
  
  def populate_warehouses
    @origin_warehouses = Warehouse.central.select(:id, :code, :name)
    if !action_name.eql?("new") && !action_name.eql?("create")
      @destination_warehouses = Warehouse.not_central.not_in_transit.not_direct_sales.actived.select(:id, :code, :name)
    end
  end
  
  def add_additional_params_to_child
    @total_quantity = 0
    @total_products = 0
    @total_deleted_products = 0
    params[:order_booking][:order_booking_products_attributes].each do |key, value|
      @total_products += 1
      @total_deleted_products += 1 if params[:order_booking][:order_booking_products_attributes][key][:_destroy].eql?("1")
      product_id = params[:order_booking][:order_booking_products_attributes][key][:product_id]
      params[:order_booking][:order_booking_products_attributes][key].merge! origin_warehouse_id: params[:order_booking][:origin_warehouse_id]
      params[:order_booking][:order_booking_products_attributes][key][:order_booking_product_items_attributes].each do |obpi_key, value|
        @total_quantity += params[:order_booking][:order_booking_products_attributes][key][:order_booking_product_items_attributes][obpi_key][:quantity].to_i unless params[:order_booking][:order_booking_products_attributes][key][:_destroy].eql?("1")
        params[:order_booking][:order_booking_products_attributes][key][:order_booking_product_items_attributes][obpi_key].merge! product_id: product_id, origin_warehouse_id: params[:order_booking][:origin_warehouse_id]
        params[:order_booking][:order_booking_products_attributes][key][:order_booking_product_items_attributes][obpi_key].merge! new_product: params[:order_booking][:order_booking_products_attributes][key][:id].blank?
      end if params[:order_booking][:order_booking_products_attributes][key][:order_booking_product_items_attributes].present?
    end if params[:order_booking][:order_booking_products_attributes].present?
  end
end
