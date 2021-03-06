class StockMovementsController < ApplicationController
  before_action :set_stock_movement, only: [:show, :edit, :update, :destroy]

  # GET /stock_movements
  # GET /stock_movements.json
  def index
    if params[:year].present?
      @selected_date = "1/#{params[:month]}/#{params[:year]}".to_date
      @warehouse = if current_user.has_non_spg_role?
        Warehouse.select(:id, :code, :name, :warehouse_type, :price_code_id).where(id: params[:warehouse_id]).first
      else
        current_user.sales_promotion_girl.warehouse
      end
      unless params[:product_code].present?
        @stock_movement_transactions = if @warehouse.warehouse_type.eql?("central")
          StockMovementTransaction.
            joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).
            includes(product_details: :price_lists).
            select(:stock_movement_product_detail_id, "SUM(purchase_order_quantity_received) AS total_po_quantity_received, SUM(purchase_return_quantity_returned) AS total_pr_quantity_returned, SUM(delivery_order_quantity_delivered) AS total_do_quantity_delivered, SUM(stock_return_quantity_received) AS total_stock_return_quantity_received, SUM(stock_movement_transactions.beginning_stock) AS total_beginning_stock, SUM(stock_movement_transactions.sold_quantity) AS total_sold_quantity, SUM(stock_movement_transactions.sales_return_quantity_received) AS total_sales_return_quantity_received, SUM(stock_movement_transactions.consignment_sold_quantity) AS total_consignment_sold_quantity, SUM(stock_movement_transactions.adjustment_in_quantity) AS total_adjustment_in_quantity, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name, stock_movement_product_details.beginning_stock, ending_stock, stock_movement_product_details.size_id, stock_movement_products.product_id").
            where(["warehouse_id = ? AND transaction_date BETWEEN ? AND ?", @warehouse.id, @selected_date.beginning_of_month, @selected_date.end_of_month]).
            group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size, :size_order, :"stock_movement_product_details.beginning_stock", :ending_stock, :"stock_movement_product_details.size_id", :"stock_movement_products.product_id").
            order("products.code, color_code, size_order")
        else
          StockMovementTransaction.
            joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).
            includes(product_details: :price_lists).
            select(:stock_movement_product_detail_id, "SUM(delivery_order_quantity_received) AS total_do_quantity_received, SUM(stock_return_quantity_returned) AS total_stock_return_quantity_returned, SUM(stock_transfer_quantity_received) AS total_stock_transfer_quantity_received, SUM(stock_transfer_quantity_delivered) AS total_stock_transfer_quantity_delivered, SUM(stock_movement_transactions.beginning_stock) AS total_beginning_stock, SUM(stock_movement_transactions.sold_quantity) AS total_sold_quantity, SUM(stock_movement_transactions.sales_return_quantity_received) AS total_sales_return_quantity_received, SUM(stock_movement_transactions.consignment_sold_quantity) AS total_consignment_sold_quantity, SUM(stock_movement_transactions.adjustment_in_quantity) AS total_adjustment_in_quantity, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name, stock_movement_product_details.beginning_stock, ending_stock, stock_movement_product_details.size_id, stock_movement_products.product_id").
            where(["warehouse_id = ? AND transaction_date BETWEEN ? AND ?", @warehouse.id, @selected_date.beginning_of_month, @selected_date.end_of_month]).
            group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size, :size_order, :"stock_movement_product_details.beginning_stock", :ending_stock, :"stock_movement_product_details.size_id", :"stock_movement_products.product_id").
            order("products.code, color_code, size_order")
        end
      else
        like_command = "ILIKE"
        @stock_movement_transactions = if @warehouse.warehouse_type.eql?("central")
          StockMovementTransaction.
            joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).
            includes(product_details: :price_lists).
            select(:stock_movement_product_detail_id, "SUM(purchase_order_quantity_received) AS total_po_quantity_received, SUM(purchase_return_quantity_returned) AS total_pr_quantity_returned, SUM(delivery_order_quantity_delivered) AS total_do_quantity_delivered, SUM(stock_return_quantity_received) AS total_stock_return_quantity_received, SUM(stock_movement_transactions.beginning_stock) AS total_beginning_stock, SUM(stock_movement_transactions.sold_quantity) AS total_sold_quantity, SUM(stock_movement_transactions.sales_return_quantity_received) AS total_sales_return_quantity_received, SUM(stock_movement_transactions.consignment_sold_quantity) AS total_consignment_sold_quantity, SUM(stock_movement_transactions.adjustment_in_quantity) AS total_adjustment_in_quantity, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name, stock_movement_product_details.beginning_stock, ending_stock, stock_movement_product_details.size_id, stock_movement_products.product_id").
            where(["warehouse_id = ? AND transaction_date BETWEEN ? AND ? AND products.code #{like_command} ?", @warehouse.id, @selected_date.beginning_of_month, @selected_date.end_of_month, "%"+params[:product_code]+"%"]).
            group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size, :size_order, :"stock_movement_product_details.beginning_stock", :ending_stock, :"stock_movement_product_details.size_id", :"stock_movement_products.product_id").
            order("products.code, color_code, size_order")
        else
          StockMovementTransaction.
            joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).
            includes(product_details: :price_lists).
            select(:stock_movement_product_detail_id, "SUM(delivery_order_quantity_received) AS total_do_quantity_received, SUM(stock_return_quantity_returned) AS total_stock_return_quantity_returned, SUM(stock_transfer_quantity_received) AS total_stock_transfer_quantity_received, SUM(stock_transfer_quantity_delivered) AS total_stock_transfer_quantity_delivered, SUM(stock_movement_transactions.beginning_stock) AS total_beginning_stock, SUM(stock_movement_transactions.sold_quantity) AS total_sold_quantity, SUM(stock_movement_transactions.sales_return_quantity_received) AS total_sales_return_quantity_received, SUM(stock_movement_transactions.consignment_sold_quantity) AS total_consignment_sold_quantity, SUM(stock_movement_transactions.adjustment_in_quantity) AS total_adjustment_in_quantity, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name, stock_movement_product_details.beginning_stock, ending_stock, stock_movement_product_details.size_id, stock_movement_products.product_id").
            where(["warehouse_id = ? AND transaction_date BETWEEN ? AND ? AND products.code #{like_command} ?", @warehouse.id, @selected_date.beginning_of_month, @selected_date.end_of_month, "%"+params[:product_code]+"%"]).
            group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size, :size_order, :"stock_movement_product_details.beginning_stock", :ending_stock, :"stock_movement_product_details.size_id", :"stock_movement_products.product_id").
            order("products.code, color_code, size_order")
        end
      end
      respond_to do |format|
        format.js
      end
    else
      user_roles = current_user.roles.pluck :name
      @warehouses = if user_roles.include?("area_manager")
        current_user.supervisor.warehouses.select(:id, :code, :name).order(:code)
      elsif user_roles.include?("staff") || user_roles.include?("manager") || user_roles.include?("administrator") || user_roles.include?("superadmin") || user_roles.include?("accountant")
        Warehouse.actived.select(:id, :code, :name).order(:code)
      end
    end
  end

  # GET /stock_movements/1
  # GET /stock_movements/1.json
  def show
  end

  # GET /stock_movements/new
  def new
    @stock_movement = StockMovement.new
  end

  # GET /stock_movements/1/edit
  def edit
  end

  # POST /stock_movements
  # POST /stock_movements.json
  def create
    @stock_movement = StockMovement.new(stock_movement_params)

    respond_to do |format|
      if @stock_movement.save
        format.html { redirect_to @stock_movement, notice: 'Stock movement was successfully created.' }
        format.json { render :show, status: :created, location: @stock_movement }
      else
        format.html { render :new }
        format.json { render json: @stock_movement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stock_movements/1
  # PATCH/PUT /stock_movements/1.json
  def update
    respond_to do |format|
      if @stock_movement.update(stock_movement_params)
        format.html { redirect_to @stock_movement, notice: 'Stock movement was successfully updated.' }
        format.json { render :show, status: :ok, location: @stock_movement }
      else
        format.html { render :edit }
        format.json { render json: @stock_movement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stock_movements/1
  # DELETE /stock_movements/1.json
  def destroy
    @stock_movement.destroy
    respond_to do |format|
      format.html { redirect_to stock_movements_url, notice: 'Stock movement was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def print
    if params[:year].present?
      @selected_date = "1/#{params[:month]}/#{params[:year]}".to_date
      @warehouse = if current_user.has_non_spg_role?
        Warehouse.select(:id, :code, :name, :warehouse_type, :price_code_id).where(id: params[:warehouse_id]).first
      else
        current_user.sales_promotion_girl.warehouse
      end
      unless params[:product_code].present?
        @stock_movement_transactions = if @warehouse.warehouse_type.eql?("central")
          StockMovementTransaction.
            joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).
            includes(product_details: :price_lists).
            select(:stock_movement_product_detail_id, "SUM(purchase_order_quantity_received) AS total_po_quantity_received, SUM(purchase_return_quantity_returned) AS total_pr_quantity_returned, SUM(delivery_order_quantity_delivered) AS total_do_quantity_delivered, SUM(stock_return_quantity_received) AS total_stock_return_quantity_received, SUM(stock_movement_transactions.beginning_stock) AS total_beginning_stock, SUM(stock_movement_transactions.sold_quantity) AS total_sold_quantity, SUM(stock_movement_transactions.sales_return_quantity_received) AS total_sales_return_quantity_received, SUM(stock_movement_transactions.consignment_sold_quantity) AS total_consignment_sold_quantity, SUM(stock_movement_transactions.adjustment_in_quantity) AS total_adjustment_in_quantity, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name, stock_movement_product_details.beginning_stock, ending_stock, stock_movement_product_details.size_id, stock_movement_products.product_id").
            where(["warehouse_id = ? AND transaction_date BETWEEN ? AND ?", @warehouse.id, @selected_date.beginning_of_month, @selected_date.end_of_month]).
            group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size, :size_order, :"stock_movement_product_details.beginning_stock", :ending_stock, :"stock_movement_product_details.size_id", :"stock_movement_products.product_id").
            order("products.code, color_code, size_order")
        else
          StockMovementTransaction.
            joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).
            includes(product_details: :price_lists).
            select(:stock_movement_product_detail_id, "SUM(delivery_order_quantity_received) AS total_do_quantity_received, SUM(stock_return_quantity_returned) AS total_stock_return_quantity_returned, SUM(stock_transfer_quantity_received) AS total_stock_transfer_quantity_received, SUM(stock_transfer_quantity_delivered) AS total_stock_transfer_quantity_delivered, SUM(stock_movement_transactions.beginning_stock) AS total_beginning_stock, SUM(stock_movement_transactions.sold_quantity) AS total_sold_quantity, SUM(stock_movement_transactions.sales_return_quantity_received) AS total_sales_return_quantity_received, SUM(stock_movement_transactions.consignment_sold_quantity) AS total_consignment_sold_quantity, SUM(stock_movement_transactions.adjustment_in_quantity) AS total_adjustment_in_quantity, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name, stock_movement_product_details.beginning_stock, ending_stock, stock_movement_product_details.size_id, stock_movement_products.product_id").
            where(["warehouse_id = ? AND transaction_date BETWEEN ? AND ?", @warehouse.id, @selected_date.beginning_of_month, @selected_date.end_of_month]).
            group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size, :size_order, :"stock_movement_product_details.beginning_stock", :ending_stock, :"stock_movement_product_details.size_id", :"stock_movement_products.product_id").
            order("products.code, color_code, size_order")
        end
      else
        like_command = "ILIKE"
        @stock_movement_transactions = if @warehouse.warehouse_type.eql?("central")
          StockMovementTransaction.
            joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).
            includes(product_details: :price_lists).
            select(:stock_movement_product_detail_id, "SUM(purchase_order_quantity_received) AS total_po_quantity_received, SUM(purchase_return_quantity_returned) AS total_pr_quantity_returned, SUM(delivery_order_quantity_delivered) AS total_do_quantity_delivered, SUM(stock_return_quantity_received) AS total_stock_return_quantity_received, SUM(stock_movement_transactions.beginning_stock) AS total_beginning_stock, SUM(stock_movement_transactions.sold_quantity) AS total_sold_quantity, SUM(stock_movement_transactions.sales_return_quantity_received) AS total_sales_return_quantity_received, SUM(stock_movement_transactions.consignment_sold_quantity) AS total_consignment_sold_quantity, SUM(stock_movement_transactions.adjustment_in_quantity) AS total_adjustment_in_quantity, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name, stock_movement_product_details.beginning_stock, ending_stock, stock_movement_product_details.size_id, stock_movement_products.product_id").
            where(["warehouse_id = ? AND transaction_date BETWEEN ? AND ? AND products.code #{like_command} ?", @warehouse.id, @selected_date.beginning_of_month, @selected_date.end_of_month, "%"+params[:product_code]+"%"]).
            group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size, :size_order, :"stock_movement_product_details.beginning_stock", :ending_stock, :"stock_movement_product_details.size_id", :"stock_movement_products.product_id").
            order("products.code, color_code, size_order")
        else
          StockMovementTransaction.
            joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).
            includes(product_details: :price_lists).
            select(:stock_movement_product_detail_id, "SUM(delivery_order_quantity_received) AS total_do_quantity_received, SUM(stock_return_quantity_returned) AS total_stock_return_quantity_returned, SUM(stock_transfer_quantity_received) AS total_stock_transfer_quantity_received, SUM(stock_transfer_quantity_delivered) AS total_stock_transfer_quantity_delivered, SUM(stock_movement_transactions.beginning_stock) AS total_beginning_stock, SUM(stock_movement_transactions.sold_quantity) AS total_sold_quantity, SUM(stock_movement_transactions.sales_return_quantity_received) AS total_sales_return_quantity_received, SUM(stock_movement_transactions.consignment_sold_quantity) AS total_consignment_sold_quantity, SUM(stock_movement_transactions.adjustment_in_quantity) AS total_adjustment_in_quantity, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name, stock_movement_product_details.beginning_stock, ending_stock, stock_movement_product_details.size_id, stock_movement_products.product_id").
            where(["warehouse_id = ? AND transaction_date BETWEEN ? AND ? AND products.code #{like_command} ?", @warehouse.id, @selected_date.beginning_of_month, @selected_date.end_of_month, "%"+params[:product_code]+"%"]).
            group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size, :size_order, :"stock_movement_product_details.beginning_stock", :ending_stock, :"stock_movement_product_details.size_id", :"stock_movement_products.product_id").
            order("products.code, color_code, size_order")
        end
      end
      respond_to do |format|
        format.js
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_stock_movement
    @stock_movement = StockMovement.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def stock_movement_params
    params.require(:stock_movement).permit(:year)
  end
end
