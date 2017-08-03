class StockMovementsController < ApplicationController
  before_action :set_stock_movement, only: [:show, :edit, :update, :destroy]

  # GET /stock_movements
  # GET /stock_movements.json
  def index
    if params[:year].present?
      @selected_date = "1/#{params[:month]}/#{params[:year]}".to_date
      @warehouse = if current_user.has_non_spg_role?
        Warehouse.select(:id, :code, :name, :warehouse_type).where(id: params[:warehouse_id]).first
      else
        current_user.sales_promotion_girl.warehouse
      end
      unless params[:product_code].present?
        @stock_movement_transactions = if @warehouse.warehouse_type.eql?("central")
          StockMovementTransaction.joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [product: :brand, stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).select("SUM(purchase_order_quantity_received) AS total_po_quantity_received, SUM(purchase_return_quantity_returned) AS total_pr_quantity_returned, SUM(delivery_order_quantity_delivered) AS total_do_quantity_delivered, SUM(stock_return_quantity_received) AS total_stock_return_quantity_received, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name").where(["warehouse_id = ? AND month = ? AND year = ? AND transaction_date BETWEEN ? AND ?", @warehouse.id, @selected_date.month, @selected_date.year, @selected_date.beginning_of_month, @selected_date.end_of_month]).group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size).order("products.code, color_code, size_order")
        else
          StockMovementTransaction.joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [product: :brand, stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).select("SUM(delivery_order_quantity_received) AS total_do_quantity_received, SUM(stock_return_quantity_returned) AS total_stock_return_quantity_returned, SUM(stock_transfer_quantity_received) AS total_stock_transfer_quantity_received, SUM(stock_transfer_quantity_delivered) AS total_stock_transfer_quantity_delivered, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name").where(["warehouse_id = ? AND month = ? AND year = ? AND transaction_date BETWEEN ? AND ?", @warehouse.id, @selected_date.month, @selected_date.year, @selected_date.beginning_of_month, @selected_date.end_of_month]).group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size).order("products.code, color_code, size_order")
        end
        @previous_stock_movement_transactions = if @warehouse.warehouse_type.eql?("central")
          StockMovementTransaction.joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).select("SUM(purchase_order_quantity_received) AS total_po_quantity_received, SUM(purchase_return_quantity_returned) AS total_pr_quantity_returned, SUM(delivery_order_quantity_delivered) AS total_do_quantity_delivered, SUM(stock_return_quantity_received) AS total_stock_return_quantity_received, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name").where(["warehouse_id = ? AND transaction_date <= ?", @warehouse.id, @selected_date.prev_month.end_of_month]).group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size)
        else
          StockMovementTransaction.joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).select("SUM(delivery_order_quantity_received) AS total_do_quantity_received, SUM(stock_return_quantity_returned) AS total_stock_return_quantity_returned, SUM(stock_transfer_quantity_received) AS total_stock_transfer_quantity_received, SUM(stock_transfer_quantity_delivered) AS total_stock_transfer_quantity_delivered, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name").where(["warehouse_id = ? AND transaction_date <= ?", @warehouse.id, @selected_date.prev_month.end_of_month]).group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size)
        end
      else
        like_command = if Rails.env.eql?("production")
          "ILIKE"
        else
          "LIKE"
        end
        @stock_movement_transactions = if @warehouse.warehouse_type.eql?("central")
          StockMovementTransaction.joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [product: :brand, stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).select("SUM(purchase_order_quantity_received) AS total_po_quantity_received, SUM(purchase_return_quantity_returned) AS total_pr_quantity_returned, SUM(delivery_order_quantity_delivered) AS total_do_quantity_delivered, SUM(stock_return_quantity_received) AS total_stock_return_quantity_received, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name").where(["warehouse_id = ? AND month = ? AND year = ? AND transaction_date BETWEEN ? AND ? AND products.code #{like_command} ?", @warehouse.id, @selected_date.month, @selected_date.year, @selected_date.beginning_of_month, @selected_date.end_of_month, "%"+params[:product_code]+"%"]).group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size).order("products.code, color_code, size_order")
        else
          StockMovementTransaction.joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [product: :brand, stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).select("SUM(delivery_order_quantity_received) AS total_do_quantity_received, SUM(stock_return_quantity_returned) AS total_stock_return_quantity_returned, SUM(stock_transfer_quantity_received) AS total_stock_transfer_quantity_received, SUM(stock_transfer_quantity_delivered) AS total_stock_transfer_quantity_delivered, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name").where(["warehouse_id = ? AND month = ? AND year = ? AND transaction_date BETWEEN ? AND ? AND products.code #{like_command} ?", @warehouse.id, @selected_date.month, @selected_date.year, @selected_date.beginning_of_month, @selected_date.end_of_month, "%"+params[:product_code]+"%"]).group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size).order("products.code, color_code, size_order")
        end
        @previous_stock_movement_transactions = if @warehouse.warehouse_type.eql?("central")
          StockMovementTransaction.joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).select("SUM(purchase_order_quantity_received) AS total_po_quantity_received, SUM(purchase_return_quantity_returned) AS total_pr_quantity_returned, SUM(delivery_order_quantity_delivered) AS total_do_quantity_delivered, SUM(stock_return_quantity_received) AS total_stock_return_quantity_received, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name").where(["warehouse_id = ? AND transaction_date <= ? AND products.code #{like_command} ?", @warehouse.id, @selected_date.prev_month.end_of_month, "%"+params[:product_code]+"%"]).group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size)
        else
          StockMovementTransaction.joins(stock_movement_product_detail: [:size, :color, stock_movement_product: [:stock_movement_warehouse, product: :brand]]).select("SUM(delivery_order_quantity_received) AS total_do_quantity_received, SUM(stock_return_quantity_returned) AS total_stock_return_quantity_returned, SUM(stock_transfer_quantity_received) AS total_stock_transfer_quantity_received, SUM(stock_transfer_quantity_delivered) AS total_stock_transfer_quantity_delivered, products.code AS product_code, common_fields.code AS color_code, common_fields.name AS color_name, size AS product_size, brands_products.name AS product_name").where(["warehouse_id = ? AND transaction_date <= ? AND products.code #{like_command} ?", @warehouse.id, @selected_date.prev_month.end_of_month, "%"+params[:product_code]+"%"]).group(:stock_movement_product_detail_id, :"products.code", :"brands_products.name", :"common_fields.code", :"common_fields.name", :size)
        end
      end
      respond_to do |format|
        format.js
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
