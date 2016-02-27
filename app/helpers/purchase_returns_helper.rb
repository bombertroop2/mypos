module PurchaseReturnsHelper
  def create_return_product_array_variable_name(purchase_return_product, product)
    if purchase_return_product.new_record?
      "purchase_return[purchase_return_products_attributes][#{Time.now.to_i.to_s+product.id.to_s}]"
    else
      "purchase_return[purchase_return_products_attributes][]"
    end
  end
  
  def create_return_item_array_variable_name(purchase_return_item, index, purchase_return_product_array_index)
    if purchase_return_item.new_record?
      "#{purchase_return_product_array_index}[purchase_return_items_attributes][#{Time.now.to_i.to_s+index.to_s}]"
    else
      "#{purchase_return_product_array_index}[purchase_return_items_attributes][]"
    end
  end

end
