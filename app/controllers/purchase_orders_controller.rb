class PurchaseOrdersController < ApplicationController
  before_action :populate_combobox_list, only: [:new, :edit]
  before_action :set_purchase_order, only: [:show, :edit, :update, :destroy]

  # GET /purchase_orders
  # GET /purchase_orders.json
  def index
    @purchase_orders = PurchaseOrder.all
  end

  # GET /purchase_orders/1
  # GET /purchase_orders/1.json
  def show
  end

  # GET /purchase_orders/new
  def new
    @purchase_order = PurchaseOrder.new
  end

  # GET /purchase_orders/1/edit
  def edit
    @store_warehouses = Warehouse.where("warehouse_type != 'central'")
    @products = @purchase_order.products
  end

  # POST /purchase_orders
  # POST /purchase_orders.json
  def create
    @purchase_order = PurchaseOrder.new(purchase_order_params)
    is_exception_raised = false
    respond_to do |format|
      begin
        if @purchase_order.save
          format.html { redirect_to @purchase_order, notice: 'Purchase order was successfully created.' }
          format.json { render :show, status: :created, location: @purchase_order }
        else
          populate_combobox_list
          @store_warehouses = Warehouse.where("warehouse_type != 'central'")
          @products = Product.find(params[:product_ids].split(",")) rescue []
          format.html { render :new }
          format.json { render json: @purchase_order.errors, status: :unprocessable_entity }
        end
        is_exception_raised = false
      rescue ActiveRecord::RecordNotUnique => e
        is_exception_raised = true
      end while is_exception_raised
    end
  end

  # PATCH/PUT /purchase_orders/1
  # PATCH/PUT /purchase_orders/1.json
  def update
    respond_to do |format|
      if @purchase_order.update(purchase_order_params)
        format.html { redirect_to @purchase_order, notice: 'Purchase order was successfully updated.' }
        format.json { render :show, status: :ok, location: @purchase_order }
      else
        format.html { render :edit }
        format.json { render json: @purchase_order.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def get_product_details
    @purchase_order = if params[:purchase_order_id].present?
      PurchaseOrder.find params[:purchase_order_id]
    else
      PurchaseOrder.new
    end
    @store_warehouses = Warehouse.where("warehouse_type != 'central'")
    @products = Product.find(params[:product_ids].split(","))
    respond_to { |format| format.js }
  end

  # DELETE /purchase_orders/1
  # DELETE /purchase_orders/1.json
  def destroy
    @purchase_order.destroy
    respond_to do |format|
      format.html { redirect_to purchase_orders_url, notice: 'Purchase order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_purchase_order
    @purchase_order = PurchaseOrder.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def purchase_order_params
    params.require(:purchase_order).permit(:number, :po_type, :status, :vendor_id, :request_delivery_date, :order_value, :receiving_value, :means_of_payment,
      :warehouse_id, purchase_order_products_attributes: [:id, :product_id, :warehouse_id,
        purchase_order_details_attributes: [:id, :product_detail_id, :quantity]])
  end
  
  def populate_combobox_list
    @suppliers = Vendor.all
    @warehouses = Warehouse.where("warehouse_type = 'central'")
  end
end
