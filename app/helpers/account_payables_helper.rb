module AccountPayablesHelper
  def get_second_discount_in_money_for_ap(purchase_order)
    if purchase_order.is_additional_disc_from_net
      value_from_first_discount = purchase_order.receiving_value - purchase_order.receiving_value * (purchase_order.first_discount.to_f / 100)
      value_from_first_discount * (purchase_order.second_discount.to_f / 100)
    else
      purchase_order.receiving_value * (purchase_order.second_discount.to_f / 100)
    end
  end
  
  def get_vat_in_money_for_ap(purchase_order)
    value_after_discount_for_ap(purchase_order) * 0.1
  end
  
  def value_after_discount_for_ap(purchase_order)
    value_after_first_discount = purchase_order.receiving_value - purchase_order.receiving_value * (purchase_order.first_discount.to_f / 100)
    value_after_second_discount = if purchase_order.is_additional_disc_from_net
      value_after_first_discount - value_after_first_discount * (purchase_order.second_discount.to_f / 100)
    elsif purchase_order.second_discount.present?
      purchase_order.receiving_value - purchase_order.receiving_value * ((purchase_order.first_discount.to_f + purchase_order.second_discount.to_f) / 100)
    end
    value_after_money_discount = purchase_order.receiving_value - purchase_order.price_discount rescue nil
    return value_after_money_discount || value_after_second_discount || value_after_first_discount
  end
  
  def value_after_ppn_for_ap(purchase_order)
    if purchase_order.value_added_tax.eql?("exclude")
      value_after_discount_for_ap(purchase_order) + get_vat_in_money_for_ap(purchase_order)
    else
      value_after_discount_for_ap(purchase_order)
    end
  end

end
