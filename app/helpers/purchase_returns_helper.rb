module PurchaseReturnsHelper
  def create_return_product_array_variable_name(purchase_return_product, product_id)
    if purchase_return_product.new_record?
      "purchase_return[purchase_return_products_attributes][#{Time.now.to_i.to_s+product_id.to_s}]"
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
  
  def is_having_stock?(pr_item, is_this_direct_purchase=false)
    unless is_this_direct_purchase
      purchase_order_detail = pr_item.purchase_order_detail rescue nil    
      quantity = purchase_order_detail.receiving_qty.to_i - purchase_order_detail.returning_qty.to_i
    else
      direct_purchase_detail = pr_item.direct_purchase_detail rescue nil    
      quantity = direct_purchase_detail.quantity.to_i - direct_purchase_detail.returning_qty.to_i rescue 0
    end
  end
  
  def total_return_value(purchase_return)
    total_value = 0
    purchase_return.purchase_return_products.each do |purchase_return_product|
      total_value += purchase_return_product.return_total_cost(purchase_return.direct_purchase_id.present?)
    end
    return total_value
  end
  
  def get_second_discount_in_money_pr(purchase_return)
    total_return_value = total_return_value(purchase_return)
    if purchase_return.purchase_order && purchase_return.purchase_order.is_additional_disc_from_net
      value_from_first_discount = total_return_value - total_return_value * (purchase_return.purchase_order.first_discount.to_f / 100)
      value_from_first_discount * (purchase_return.purchase_order.second_discount.to_f / 100)
    elsif purchase_return.direct_purchase && purchase_return.direct_purchase.is_additional_disc_from_net
      value_from_first_discount = total_return_value - total_return_value * (purchase_return.direct_purchase.first_discount.to_f / 100)
      value_from_first_discount * (purchase_return.direct_purchase.second_discount.to_f / 100)
    elsif purchase_return.purchase_order
      total_return_value * (purchase_return.purchase_order.second_discount.to_f / 100)
    else
      total_return_value * (purchase_return.direct_purchase.second_discount.to_f / 100)
    end
  end
  
  def value_after_discount_pr(purchase_return)
    total_return_value = total_return_value(purchase_return)
    value_after_first_discount = total_return_value - total_return_value * ((purchase_return.purchase_order.first_discount.to_f rescue purchase_return.direct_purchase.first_discount.to_f) / 100)
    value_after_second_discount = if purchase_return.purchase_order && purchase_return.purchase_order.is_additional_disc_from_net
      value_after_first_discount - value_after_first_discount * (purchase_return.purchase_order.second_discount.to_f / 100)
    elsif purchase_return.direct_purchase && purchase_return.direct_purchase.is_additional_disc_from_net
      value_after_first_discount - value_after_first_discount * (purchase_return.direct_purchase.second_discount.to_f / 100)
    elsif purchase_return.purchase_order && purchase_return.purchase_order.second_discount.present?
      total_return_value - total_return_value * ((purchase_return.purchase_order.first_discount.to_f + purchase_return.purchase_order.second_discount.to_f) / 100)
    elsif purchase_return.direct_purchase && purchase_return.direct_purchase.second_discount.present?
      total_return_value - total_return_value * ((purchase_return.direct_purchase.first_discount.to_f + purchase_return.direct_purchase.second_discount.to_f) / 100)
    end
    value_after_money_discount = total_return_value - (purchase_return.purchase_order.price_discount rescue purchase_return.direct_purchase.price_discount) rescue nil
    return value_after_money_discount || value_after_second_discount || value_after_first_discount
  end
  
  def get_vat_in_money_pr(purchase_return)
    value_after_discount_pr(purchase_return) * 0.1
  end
  
  def value_after_ppn_pr(purchase_return)
    if (purchase_return.purchase_order && purchase_return.purchase_order.value_added_tax.eql?("exclude")) || (purchase_return.direct_purchase && purchase_return.direct_purchase.vat_type.eql?("exclude"))
      value_after_discount_pr(purchase_return) + get_vat_in_money_pr(purchase_return)
    else
      value_after_discount_pr(purchase_return)
    end
  end

end
