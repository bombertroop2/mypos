class ReceivingController < ApplicationController
  before_action :set_purchase_order, only: [:get_purchase_order, :receive_products_from_purchase_order]
  before_action :convert_price_discount_to_numeric, only: :create
  
  def new
    @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name")
    @suppliers = Vendor.all
    @warehouses = Warehouse.select :id, :code
    @direct_purchase = DirectPurchase.new
    @direct_purchase.build_received_purchase_order is_using_delivery_order: true, is_it_direct_purchasing: true
  end
  
  def get_purchase_order    
    @purchase_order.receiving_po = true
    received_purchase_order = @purchase_order.received_purchase_orders.build
    @purchase_order.purchase_order_products.joins(:product).select("purchase_order_products.id, code").each do |po_product|
      received_purchase_order_product = received_purchase_order.received_purchase_order_products.build purchase_order_product_id: po_product.id
      po_product.purchase_order_details.select(:id).each do |purchase_order_detail|
        received_purchase_order_product.received_purchase_order_items.build purchase_order_detail_id: purchase_order_detail.id
      end
    end
    respond_to { |format| format.js }
  end
  
  def receive_products_from_purchase_order    
    respond_to do |format|
      if @purchase_order.update(purchase_order_params)
        format.html { redirect_to new_receiving_url, notice: 'Products were successfully received.' }
        format.json { head :no_content }
      else        
        @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name")
        @suppliers = Vendor.all
        @warehouses = Warehouse.select :id, :code
        @direct_purchase = DirectPurchase.new
        @direct_purchase.build_received_purchase_order is_using_delivery_order: true
        received_purchase_order = @purchase_order.received_purchase_orders.select{|rpo| rpo.new_record?}.first
        @purchase_order.purchase_order_products.joins(:product).select("purchase_order_products.id, code").each do |po_product|
          received_purchase_order_product = received_purchase_order.received_purchase_order_products.select{|rpop| rpop.purchase_order_product_id.eql?(po_product.id)}.first
          received_purchase_order_product = received_purchase_order.received_purchase_order_products.build purchase_order_product_id: po_product.id if received_purchase_order_product.blank?
          po_product.purchase_order_details.select(:id).each do |purchase_order_detail|
            if received_purchase_order_product.received_purchase_order_items.select{|rpoi| rpoi.purchase_order_detail_id.eql?(purchase_order_detail.id)}.blank?
              received_purchase_order_product.received_purchase_order_items.build purchase_order_detail_id: purchase_order_detail.id
            end
          end
        end
        if @purchase_order.errors[:base].present?
          flash.now[:alert] = @purchase_order.errors[:base].to_sentence
        elsif @purchase_order.errors[:"received_purchase_orders.base"].present?
          flash.now[:alert] = @purchase_order.errors[:"received_purchase_orders.base"].to_sentence
        end        
        format.html { render action: "new" }
        format.json { render json: @purchase_order.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def get_product_details
    previous_selected_product_ids = params[:previous_selected_product_ids]
    selected_product_ids = params[:product_ids]
    splitted_selected_product_ids = selected_product_ids.split(",") - previous_selected_product_ids.split(",")
    @direct_purchase = DirectPurchase.new
    if splitted_selected_product_ids.present?
      @colors = Color.select(:id, :code).order :code
      @products = Product.where("id IN (#{splitted_selected_product_ids.join(",")})").select(:id, :code)
      @products.each do |product|
        existing_dpp = @direct_purchase.direct_purchase_products.select{|dpp| dpp.product_id.eql?(product.id)}.first
        dpp = if existing_dpp.nil?
          @direct_purchase.direct_purchase_products.build product_id: product.id
        else
          existing_dpp        
        end
        #        pop = @purchase_order.purchase_order_products.build product_id: product.id
        product.grouped_product_details.each do |gpd|
          @colors.each do |color|
            existing_item = dpp.direct_purchase_details.select{|dpd| dpd.size_id.eql?(gpd.size.id) and dpd.color_id.eql?(color.id)}.first
            dpp.direct_purchase_details.build size_id: gpd.size.id, color_id: color.id unless existing_item
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
  
  def create
    @direct_purchase = DirectPurchase.new(direct_purchase_params)
    @direct_purchase.received_purchase_order.is_it_direct_purchasing = true
    respond_to do |format|
      if @direct_purchase.save
        format.html { redirect_to new_receiving_url, notice: 'Products were successfully received.' }
        format.json { render :show, status: :created, location: @direct_purchase }
      else
        @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name")
        @suppliers = Vendor.all
        @warehouses = Warehouse.select :id, :code
        @colors = Color.select(:id, :code).order :code
        @products = Product.where("id IN (#{params[:product_ids]})").select(:id, :code)

        @direct_purchase.direct_purchase_products.each do |dpp|
          dpp.product.grouped_product_details.each do |gpd|
            @colors.each do |color|
              dpp.direct_purchase_details.build size_id: gpd.size.id, color_id: color.id if dpp.direct_purchase_details.select{|dpd| dpd.size_id.eql?(gpd.size.id) and dpd.color_id.eql?(color.id)}.blank?
            end
          end
        end
          
        if @direct_purchase.errors[:base].present?
          flash.now[:alert] = @direct_purchase.errors[:base].to_sentence
        elsif @direct_purchase.errors[:"direct_purchase_products.base"].present?
          flash.now[:alert] = @direct_purchase.errors[:"direct_purchase_products.base"].to_sentence
        end
        
        format.html { render :new }
        format.json { render json: @direct_purchase.errors, status: :unprocessable_entity }
      end
    end
  end
  
  private
  
  def purchase_order_params
    params.require(:purchase_order).permit(:id, received_purchase_orders_attributes: [:is_using_delivery_order, :delivery_order_number, 
        received_purchase_order_products_attributes: [:purchase_order_product_id, received_purchase_order_items_attributes: [:purchase_order_detail_id, :quantity]]]).merge(receiving_po: true)
  end
  
  def direct_purchase_params
    params.require(:direct_purchase).permit(:receiving_date, :vendor_id, :warehouse_id, :first_discount, :second_discount, :is_additional_disc_from_net, :price_discount,
      received_purchase_order_attributes: [:is_it_direct_purchasing, :is_using_delivery_order, :delivery_order_number], 
      direct_purchase_products_attributes: [:product_id,
        direct_purchase_details_attributes: [:size_id, :color_id, :quantity]])
  end
  
  def set_purchase_order
    @purchase_order = PurchaseOrder.where(id: params[:id]).select("purchase_orders.id, number, name, purchase_order_date, status, first_discount, second_discount, price_discount").joins(:vendor).first
  end
  
  def convert_price_discount_to_numeric
    params[:direct_purchase][:price_discount] = params[:direct_purchase][:price_discount].gsub("Rp","").gsub(".","").gsub(",",".") if params[:direct_purchase][:price_discount].present?
  end
end
