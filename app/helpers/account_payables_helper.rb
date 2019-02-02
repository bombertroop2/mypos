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

  def get_include_vat_in_money_for_ap(purchase_order)
    (value_after_discount_for_ap(purchase_order) / 1.1 * 0.1).round(2)
  end
  
  def value_after_discount_for_ap(purchase_order)
    value_after_first_discount = purchase_order.receiving_value - purchase_order.receiving_value * (purchase_order.first_discount.to_f / 100)
    value_after_second_discount = if purchase_order.is_additional_disc_from_net
      value_after_first_discount - value_after_first_discount * (purchase_order.second_discount.to_f / 100)
    elsif purchase_order.second_discount.present?
      purchase_order.receiving_value - purchase_order.receiving_value * ((purchase_order.first_discount.to_f + purchase_order.second_discount.to_f) / 100)
    end
    return value_after_second_discount || value_after_first_discount
  end
  
  def value_after_ppn_for_ap(purchase_order)
    vat_type = purchase_order.value_added_tax rescue purchase_order.vat_type
    if vat_type.eql?("exclude")
      value_after_discount_for_ap(purchase_order) + get_vat_in_money_for_ap(purchase_order)
    else
      value_after_discount_for_ap(purchase_order)
    end
  end
  
  def get_second_discount_in_money_for_ap_partial(received_purchase_order, purchase_type, gross_amount)
    if purchase_type.eql?("order")
      if received_purchase_order.po_is_additional_disc_from_net == true
        value_from_first_discount = gross_amount - (received_purchase_order.po_first_discount.to_f / 100) * gross_amount
        value_from_first_discount * (received_purchase_order.po_second_discount.to_f / 100)
      else
        gross_amount * (received_purchase_order.po_second_discount.to_f / 100)
      end
    else
      if received_purchase_order.dp_is_additional_disc_from_net == true
        value_from_first_discount = gross_amount - (received_purchase_order.dp_first_discount.to_f / 100) * gross_amount
        value_from_first_discount * (received_purchase_order.dp_second_discount.to_f / 100)
      else
        gross_amount * (received_purchase_order.dp_second_discount.to_f / 100)
      end
    end
  end
  
  def get_include_vat_in_money_for_ap_partial(received_purchase_order, purchase_type, gross_amount)
    (value_after_discount_for_ap_partial(received_purchase_order, purchase_type, gross_amount) / 1.1 * 0.1).round(2)
  end
  
  def value_after_discount_for_ap_partial(received_purchase_order, purchase_type, gross_amount)
    if purchase_type.eql?("order")
      value_after_first_discount = gross_amount - gross_amount * (received_purchase_order.po_first_discount.to_f / 100)
      value_after_second_discount = if received_purchase_order.po_is_additional_disc_from_net == true
        value_after_first_discount - value_after_first_discount * (received_purchase_order.po_second_discount.to_f / 100)
      elsif received_purchase_order.po_second_discount.present?
        gross_amount - gross_amount * ((received_purchase_order.po_first_discount.to_f + received_purchase_order.po_second_discount.to_f) / 100)
      end
      return value_after_second_discount || value_after_first_discount
    else
      value_after_first_discount = gross_amount - gross_amount * (received_purchase_order.dp_first_discount.to_f / 100)
      value_after_second_discount = if received_purchase_order.dp_is_additional_disc_from_net == true
        value_after_first_discount - value_after_first_discount * (received_purchase_order.dp_second_discount.to_f / 100)
      elsif received_purchase_order.dp_second_discount.present?
        gross_amount - gross_amount * ((received_purchase_order.dp_first_discount.to_f + received_purchase_order.dp_second_discount.to_f) / 100)
      end
      return value_after_second_discount || value_after_first_discount
    end
  end
  
  def get_vat_in_money_for_ap_partial(received_purchase_order, purchase_type, gross_amount)
    value_after_discount_for_ap_partial(received_purchase_order, purchase_type, gross_amount) * 0.1
  end
  
  def value_after_ppn_for_ap_partial(received_purchase_order, purchase_type, gross_amount)
    vat_type = if purchase_type.eql?("order")
      received_purchase_order.po_vat_type
    else
      received_purchase_order.dp_vat_type
    end
    if vat_type.eql?("exclude")
      value_after_discount_for_ap_partial(received_purchase_order, purchase_type, gross_amount) + get_vat_in_money_for_ap_partial(received_purchase_order, purchase_type, gross_amount)
    else
      value_after_discount_for_ap_partial(received_purchase_order, purchase_type, gross_amount)
    end
  end

end
