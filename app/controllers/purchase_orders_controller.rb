class PurchaseOrdersController < ApplicationController
  before_action :populate_combobox_list, only: [:new, :edit]
  before_action :set_purchase_order, only: [:show, :edit, :update, :destroy, :receive]

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
    @purchase_order.request_delivery_date = @purchase_order.request_delivery_date.strftime("%d/%m/%Y")
    @store_warehouses = Warehouse.where("warehouse_type != 'central'")
    @products = @purchase_order.products
    @colors = Color.order :code
    @purchase_order.purchase_order_products.each do |pop|
      pop.product.grouped_product_details.each do |gpd|
        @colors.each do |color|
          pop.purchase_order_details.build size_id: gpd.size.id, color_id: color.id if pop.purchase_order_details.select{|pod| pod.size_id.eql?(gpd.size.id) and pod.color_id.eql?(color.id)}.blank?
        end
      end
    end
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
          @colors = Color.order :code
          @store_warehouses = Warehouse.where("warehouse_type != 'central'")
          @products = Product.find(params[:product_ids].split(",")) rescue []
          @purchase_order.purchase_order_products.each do |pop|
            pop.product.grouped_product_details.each do |gpd|
              @colors.each do |color|
                pop.purchase_order_details.build size_id: gpd.size.id, color_id: color.id if pop.purchase_order_details.select{|pod| pod.size_id.eql?(gpd.size.id) and pod.color_id.eql?(color.id)}.blank?
              end
            end
          end
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
        format.html { 
          if @purchase_order
            redirect_to @purchase_order, notice: 'Purchase order was successfully updated.'
          else
            redirect_to purchase_returns_url, notice: "Purchase order was successfully destroyed."
          end
        }
        format.json { render :show, status: :ok, location: @purchase_order }
      else
        populate_combobox_list
        @store_warehouses = Warehouse.where("warehouse_type != 'central'")
        @products = Product.find(params[:product_ids].split(",")) rescue []
        @colors = Color.order :code
        @purchase_order.purchase_order_products.each do |pop|
          pop.product.grouped_product_details.each do |gpd|
            @colors.each do |color|
              pop.purchase_order_details.build size_id: gpd.size.id, color_id: color.id if pop.purchase_order_details.select{|pod| pod.size_id.eql?(gpd.size.id) and pod.color_id.eql?(color.id)}.blank?
            end
          end
        end
        
        # ambil id produk yang diganti, untuk ditandai remove dan disembunyikan di form
        previous_selected_product_ids = @purchase_order.purchase_order_products.pluck(:product_id)
        selected_product_ids = params[:product_ids]
        splitted_selected_product_ids = selected_product_ids.split(",") - previous_selected_product_ids.map(&:to_s)
        if splitted_selected_product_ids.present?
          # id yang diganti, caranya yang lama dihapus dan yang baru ditambahkan      
          @replaced_ids = previous_selected_product_ids.map(&:to_s) - selected_product_ids.split(",")
        end
        
        format.html { render :edit }
        format.json { render json: @purchase_order.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def get_product_details
    previous_selected_product_ids = params[:previous_selected_product_ids]
    selected_product_ids = params[:product_ids]
    splitted_selected_product_ids = selected_product_ids.split(",") - previous_selected_product_ids.split(",")
    @purchase_order = if params[:purchase_order_id].present?
      PurchaseOrder.find params[:purchase_order_id]
    else
      PurchaseOrder.new
    end
    if splitted_selected_product_ids.present?
      @colors = Color.order :code
      @store_warehouses = Warehouse.where("warehouse_type != 'central'")
      @products = Product.find(splitted_selected_product_ids)
      @products.each do |product|
        existing_pop = @purchase_order.purchase_order_products.select{|pop| pop.product_id.eql?(product.id)}.first
        pop = if existing_pop.nil?
          @purchase_order.purchase_order_products.build product_id: product.id
        else
          existing_pop        
        end
        #        pop = @purchase_order.purchase_order_products.build product_id: product.id
        product.grouped_product_details.each do |gpd|
          @colors.each do |color|
            existing_item = pop.purchase_order_details.select{|pod| pod.size_id.eql?(gpd.size.id) and pod.color_id.eql?(color.id)}.first
            pop.purchase_order_details.build size_id: gpd.size.id, color_id: color.id unless existing_item
          end
        end
      end

      # id yang diganti, caranya yang lama dihapus dan yang baru ditambahkan      
      @replaced_ids = previous_selected_product_ids.split(",") - selected_product_ids.split(",")
      respond_to { |format| format.js }
    else
      previous_selected_product_ids = params[:previous_selected_product_ids]
      selected_product_ids = params[:product_ids]
      if previous_selected_product_ids.split(",").length > selected_product_ids.split(",").length
        @removed_ids = previous_selected_product_ids.split(",") - selected_product_ids.split(",")
        respond_to { |format| format.js }
      else
        render nothing: true
      end      
    end
  end

  # DELETE /purchase_orders/1
  # DELETE /purchase_orders/1.json
  def destroy
    unless @purchase_order.destroy
      alert = @purchase_order.errors.full_messages.first 
    else
      notice = 'Purchase order was successfully deleted.'
    end
    respond_to do |format|
      format.html do 
        if notice.present?
          redirect_to purchase_orders_url, notice: notice
        else
          redirect_to purchase_orders_url, alert: alert
        end
      end
      format.json { head :no_content }
    end
  end
  
  def receive
    if request.method.eql?("POST")
      respond_to do |format|
        if @purchase_order.update(purchase_order_params)
          format.html { redirect_to purchase_orders_url, notice: 'Purchase order was successfully updated.' }
          format.json { head :no_content }
        else
          @purchase_order.receiving_po = true
          @purchase_order.purchase_order_products.each do |po_product|
            po_product.colors.each do |color|
              po_product.received_purchase_orders.build(color_id: color.id) if po_product.received_purchase_orders.where(color_id: color.id).first.nil?
            end
          end
          format.html { render action: "receive" }
          format.json { render json: @purchase_order.errors, status: :unprocessable_entity }
        end
      end
    else
      @purchase_order.receiving_po = true
      @purchase_order.purchase_order_products.each do |po_product|
        po_product.colors.each do |color|
          po_product.received_purchase_orders.build(color_id: color.id) if po_product.received_purchase_orders.where(color_id: color.id).first.nil?
        end
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_purchase_order
    @purchase_order = PurchaseOrder.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def purchase_order_params
    params.require(:purchase_order).permit(:receiving_po, :number, :po_type, :status, :vendor_id, :request_delivery_date, :order_value, :receiving_value,
      :warehouse_id, purchase_order_products_attributes: [:id, :product_id, :warehouse_id, :_destroy,
        purchase_order_details_attributes: [:id, :size_id, :color_id, :quantity], received_purchase_orders_attributes: [:id, :color_id, :purchase_order_product_id, :is_received]])
  end
  
  def populate_combobox_list
    @suppliers = Vendor.all
    @warehouses = Warehouse.where("warehouse_type = 'central'")
  end
end
