class ReceivingController < ApplicationController
  before_action :set_purchase_order, only: [:get_purchase_order, :receive_products_from_purchase_order]
  
  def new
    @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name")
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
        format.html { redirect_to new_receiving_url, notice: 'Purchase order was successfully updated.' }
        format.json { head :no_content }
      else
        @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name")
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
  
  private
  
  def purchase_order_params
    params.require(:purchase_order).permit(:id, received_purchase_orders_attributes: [:is_using_delivery_order, :delivery_order_number, 
        received_purchase_order_products_attributes: [:purchase_order_product_id, received_purchase_order_items_attributes: [:purchase_order_detail_id, :quantity]]]).merge(receiving_po: true)
  end
  
  def set_purchase_order
    @purchase_order = PurchaseOrder.where(id: params[:id]).select("purchase_orders.id, number, name, purchase_order_date, status, first_discount, second_discount, price_discount").joins(:vendor).first
  end
end
