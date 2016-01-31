module PurchaseOrdersHelper
  def selected_product_collection
    return params[:product_collections] if params[:product_collections]
    return @products.map(&:id) if @products.present?
  end
  
  
  def get_or_build_purchase_order_product_object(purchase_order, product)
    purchase_order_product_detail = purchase_order.purchase_order_products.select{|pop| pop.product.eql?(product)}.first
    unless purchase_order_product_detail
      purchase_order_product_detail = purchase_order.purchase_order_products.build(product: product)
    end
    purchase_order_product_detail
  end
  
  def get_or_build_purchase_order_detail_object(purchase_order_product, product_detail)    
    purchase_order_detail_detail = purchase_order_product.purchase_order_details.select{|pod| pod.product_detail.eql?(product_detail)}.first
    unless purchase_order_detail_detail
      purchase_order_detail_detail = purchase_order_product.purchase_order_details.build(product_detail: product_detail)
    end
    purchase_order_detail_detail
  end
  
  def create_product_array_variable_name(purchase_order_product, product)
    if purchase_order_product.new_record?
      "purchase_order[purchase_order_products_attributes][#{Time.now.to_i.to_s+product.id.to_s}]"
    else
      "purchase_order[purchase_order_products_attributes][]"
    end
  end
  
  def create_product_detail_array_variable_name(purchase_order_detail, index, purchase_order_product_array_index)    
    if purchase_order_detail.new_record?
      "#{purchase_order_product_array_index}[purchase_order_details_attributes][#{Time.now.to_i.to_s+index.to_s}]"
    else
      "#{purchase_order_product_array_index}[purchase_order_details_attributes][]"
    end
  end
end
