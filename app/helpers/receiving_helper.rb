module ReceivingHelper
  def create_direct_purchase_product_array_variable_name(product_id)
    "direct_purchase[direct_purchase_products_attributes][#{Time.now.to_i.to_s+product_id.to_s}]"
  end
  
  def create_direct_purchase_detail_array_variable_name(index, direct_purchase_product_array_index)
    "#{direct_purchase_product_array_index}[direct_purchase_details_attributes][#{Time.now.to_i.to_s+index.to_s}]"
  end
end
