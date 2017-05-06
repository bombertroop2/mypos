include SmartListing::Helper::ControllerExtensions
class PurchaseOrdersController < ApplicationController
  helper SmartListing::Helper
  before_action :populate_combobox_list, :populate_products, only: [:new, :edit]
  before_action :set_purchase_order, only: [:show, :edit, :update, :destroy, :close]

  # GET /purchase_orders
  # GET /purchase_orders.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    po_scope = PurchaseOrder.joins(:vendor).select("purchase_orders.id, number, po_type, status, vendors.name AS vendor_name")
    if request.xhr?
      po_scope = po_scope.where(["number #{like_command} ?", "%"+params[:filter]+"%"]).
        or(po_scope.where(["po_type #{like_command} ?", "%"+params[:filter]+"%"])).
        or(po_scope.where(["status #{like_command} ?", "%"+params[:filter]+"%"])).
        or(po_scope.where(["vendors.name #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    else
      po_scope = po_scope.where("status = 'Open'")
    end
    @purchase_orders = smart_listing_create(:purchase_orders, po_scope, partial: 'purchase_orders/listing', default_sort: {:"DATE(request_delivery_date)" => "ASC"})
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
    unless @purchase_order.status.eql?("Deleted")
      @purchase_order.request_delivery_date = @purchase_order.request_delivery_date.strftime("%d/%m/%Y")
      @purchase_order.purchase_order_date = @purchase_order.purchase_order_date.strftime("%d/%m/%Y") if @purchase_order.purchase_order_date
      @products = @purchase_order.products.select :id
      @purchase_order.purchase_order_products.each do |pop|
        colors = pop.product.colors.select :id
        sizes = pop.product.sizes.select :id
        colors.each do |color|
          sizes.each do |size|
            pop.purchase_order_details.build size_id: size.id, color_id: color.id             
          end
        end
      end
    else
      redirect_to purchase_orders_url, alert: "Sorry, this PO is not editable"
    end
  end

  # POST /purchase_orders
  # POST /purchase_orders.json
  def create
    add_additional_params_to_purchase_order_products(params[:purchase_order][:purchase_order_date])
    @purchase_order = PurchaseOrder.new(purchase_order_params)

    unless @purchase_order.save
      populate_combobox_list
      populate_products
      @products = Product.where(id: params[:product_ids].split(",")).select(:id)
      @purchase_order.purchase_order_products.each do |pop|
        colors = pop.product.colors.select :id
        sizes = pop.product.sizes.select :id
        colors.each do |color|
          sizes.each do |size|
            pop.purchase_order_details.build size_id: size.id, color_id: color.id #if pop.purchase_order_details.select(:id, :quantity, :size_id, :color_id).select{|pod| pod.size_id.eql?(gpd.size_id) and pod.color_id.eql?(color.id)}.blank?
          end
        end
      end
        
      render js: "bootbox.alert({message: \"#{@purchase_order.errors[:base].join("\\n")}\",size: 'small'});" if @purchase_order.errors[:base].present?
    else
      @vendor_name = Vendor.select(:name).find_by(id: @purchase_order.vendor_id).name rescue nil
    end
  rescue ActiveRecord::RecordNotUnique => e
    render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
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
        populate_products
        @products = Product.where(id: params[:product_ids].split(",")).select(:id)
        @purchase_order.purchase_order_products.each do |pop|
          colors = pop.product.colors.select :id
          sizes = pop.product.sizes.select :id
          colors.each do |color|
            sizes.each do |size|  
              pop.purchase_order_details.build size_id: size.id, color_id: color.id #if pop.purchase_order_details.select{|pod| pod.size_id.eql?(gpd.size_id) and pod.color_id.eql?(color.id)}.blank?              
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
        
        if @purchase_order.errors[:base].present?
          flash.now[:alert] = @purchase_order.errors[:base].to_sentence
        end
        
        format.html { render :edit }
        format.json { render json: @purchase_order.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def get_product_details
    @product_costs = Hash.new
    previous_selected_product_ids = params[:previous_selected_product_ids]
    selected_product_ids = params[:product_ids]
    splitted_selected_product_ids = selected_product_ids.split(",") - previous_selected_product_ids.split(",")
    @purchase_order = if params[:purchase_order_id].present?
      PurchaseOrder.where(id: params[:purchase_order_id]).
        select(:id).first
    else
      PurchaseOrder.new
    end
    if splitted_selected_product_ids.present?      
      products = Product.where(id: splitted_selected_product_ids).select(:id)
      products.each do |product|
        colors = product.colors.select :id
        sizes = product.sizes.select :id
        active_cost = product.active_cost_by_po_date(params[:po_date].to_date).cost rescue 0
        @product_costs[product.id] = active_cost
        pop = @purchase_order.purchase_order_products.build product_id: product.id, po_cost: active_cost
        colors.each do |color|
          sizes.each do |size|
            pop.purchase_order_details.build size_id: size.id, color_id: color.id #unless existing_item
          end
        end        
      end

      # id yang diganti, caranya yang lama dihapus dan yang baru ditambahkan      
      @replaced_ids = previous_selected_product_ids.split(",") - selected_product_ids.split(",")
      respond_to { |format| format.js }
    else      
      if previous_selected_product_ids.split(",").length > selected_product_ids.split(",").length
        @removed_ids = previous_selected_product_ids.split(",") - selected_product_ids.split(",")
        products = Product.where(id: selected_product_ids.split(",")).select(:id)
        products.each do |product|
          active_cost = product.active_cost_by_po_date(params[:po_date].to_date).cost rescue 0
          @product_costs[product.id] = active_cost
        end
        respond_to { |format| format.js }
      else
        products = Product.where(id: selected_product_ids.split(",")).select(:id)
        products.each do |product|
          active_cost = product.active_cost_by_po_date(params[:po_date].to_date).cost rescue 0
          @product_costs[product.id] = active_cost
        end
        respond_to do |format|
          format.js { render 'update_cost' }
        end
      end      
    end
  end

  # DELETE /purchase_orders/1
  # DELETE /purchase_orders/1.json
  def destroy    
    @old_status = @purchase_order.status
    @purchase_order.deleting_po = true
    @valid = @purchase_order.update(status: "Deleted")

  end
    
  def close
    @old_status = @purchase_order.status
    @purchase_order.closing_po = true
    @valid = @purchase_order.update(status: "Closed")
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_purchase_order
    @purchase_order = PurchaseOrder.joins(:vendor, :warehouse).where(id: params[:id]).
      select("po_type, note, warehouse_id, vendor_id, status, number, vendors.name AS vendor_name, terms_of_payment, purchase_orders.created_at, purchase_order_date, request_delivery_date, order_value, first_discount, second_discount, is_additional_disc_from_net, purchase_orders.value_added_tax, warehouses.code AS warehouse_code, warehouses.address AS warehouse_address, purchase_orders.is_taxable_entrepreneur, purchase_orders.id").first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def purchase_order_params
    params.require(:purchase_order).permit(:note, :is_additional_disc_from_net, :first_discount, :second_discount, :receiving_po, :number, :po_type, :status, :vendor_id, :request_delivery_date, :order_value, :receiving_value,
      :warehouse_id, :purchase_order_date, purchase_order_products_attributes: [:po_cost, :product_id, :purchase_order_date,
        purchase_order_details_attributes: [:size_id, :color_id, :quantity, :product_id]], received_purchase_orders_attributes: [:is_using_delivery_order, :delivery_order_number, 
        received_purchase_order_products_attributes: [:purchase_order_product_id, received_purchase_order_items_attributes: [:purchase_order_detail_id, :quantity]]]).merge(created_by: current_user.id)
  end
  
  def populate_combobox_list
    @suppliers = Vendor.select(:id, :name)
    @warehouses = Warehouse.where("warehouse_type = 'central'").select(:id, :code)
  end
  
  def populate_products
    @product_list = Product.joins(:brand).select("products.id, products.code, common_fields.name AS brand_name").order(:code)
  end
  
  def add_additional_params_to_purchase_order_products(po_date)
    params[:purchase_order][:purchase_order_products_attributes].each do |key, value|
      params[:purchase_order][:purchase_order_products_attributes][key].merge! purchase_order_date: po_date
    end if params[:purchase_order][:purchase_order_products_attributes].present?
  end
end
