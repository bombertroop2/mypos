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
  
  def is_having_stock?(pr_item)
    purchase_order_detail = pr_item.purchase_order_detail rescue nil
    purchase_order_product = purchase_order_detail.purchase_order_product rescue nil
    product = purchase_order_product.product rescue nil
    warehouse = purchase_order_product.purchase_order.warehouse rescue nil
    stock_product = warehouse.stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first rescue nil
    size = purchase_order_detail.size rescue nil
    color = purchase_order_detail.color rescue nil
    quantity = stock_product.stock_details.select{|sd| sd.size_id.eql?(size.id) && sd.color_id.eql?(color.id)}.first.quantity rescue nil
  end

end
