module PurchaseOrdersHelper
  def selected_product_collection
    return params[:product_collections] if params[:product_collections]
    return @products.map(&:id) if @products.present?
  end
  
  def get_or_build_received_po_object(po_product, color)
    received_purchase_order_detail = po_product.received_purchase_orders.select{|rpo| rpo.color.eql?(color)}.first
    unless received_purchase_order_detail
      received_purchase_order_detail = po_product.received_purchase_orders.build(color: color)
    end
    received_purchase_order_detail
  end
  
  def get_or_build_purchase_order_product_object(purchase_order, product)
    purchase_order_product_detail = purchase_order.purchase_order_products.select{|pop| pop.product_id.eql?(product.id)}.first
    unless purchase_order_product_detail
      purchase_order_product_detail = purchase_order.purchase_order_products.build(product_id: product.id)
    end
    purchase_order_product_detail
  end
  
  def get_or_build_purchase_order_detail_object(purchase_order_product, size, color)    
    purchase_order_detail_detail = purchase_order_product.purchase_order_details.select{|pod| pod.size.eql?(size) and pod.color.eql?(color)}.first
    unless purchase_order_detail_detail
      purchase_order_detail_detail = purchase_order_product.purchase_order_details.build(size: size, color: color)
    end
    purchase_order_detail_detail
  end
  
  def create_product_array_variable_name(purchase_order_product, product)
    if purchase_order_product.new_record?
      "purchase_order[purchase_order_products_attributes][#{Time.now.to_i.to_s+product.id.to_s}]"
    else
      "purchase_order[purchase_order_products_attributes][#{purchase_order_product.id}]"
    end
  end
  
  def create_product_detail_array_variable_name(purchase_order_detail, index, purchase_order_product_array_index)    
    if purchase_order_detail.new_record?
      "#{purchase_order_product_array_index}[purchase_order_details_attributes][#{Time.now.to_i.to_s+index.to_s}]"
    else
      "#{purchase_order_product_array_index}[purchase_order_details_attributes][]"
    end
  end
  
  def create_received_purchase_order_array_variable_name(received_po_detail, purchase_order_product, color)
      "purchase_order[purchase_order_products_attributes][#{purchase_order_product.id}][received_purchase_orders_attributes][#{color.id}]"
  end
end
