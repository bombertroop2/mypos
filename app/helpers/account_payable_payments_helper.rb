module AccountPayablePaymentsHelper
  def get_second_discount_in_money_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount)
    if purchase_type.eql?("order")
      if account_payable_purchase_partial.received_purchase_order.purchase_order.is_additional_disc_from_net == true
        value_from_first_discount = gross_amount - (account_payable_purchase_partial.received_purchase_order.purchase_order.first_discount.to_f / 100) * gross_amount
        value_from_first_discount * (account_payable_purchase_partial.received_purchase_order.purchase_order.second_discount.to_f / 100)
      else
        gross_amount * (account_payable_purchase_partial.received_purchase_order.purchase_order.second_discount.to_f / 100)
      end
    else
      if account_payable_purchase_partial.received_purchase_order.direct_purchase.is_additional_disc_from_net == true
        value_from_first_discount = gross_amount - (account_payable_purchase_partial.received_purchase_order.direct_purchase.first_discount.to_f / 100) * gross_amount
        value_from_first_discount * (account_payable_purchase_partial.received_purchase_order.direct_purchase.second_discount.to_f / 100)
      else
        gross_amount * (account_payable_purchase_partial.received_purchase_order.direct_purchase.second_discount.to_f / 100)
      end
    end
  end
  
  def get_include_vat_in_money_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount)
    (value_after_discount_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount) / 1.1 * 0.1).round(2)
  end
  
  def value_after_discount_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount)
    if purchase_type.eql?("order")
      value_after_first_discount = gross_amount - gross_amount * (account_payable_purchase_partial.received_purchase_order.purchase_order.first_discount.to_f / 100)
      value_after_second_discount = if account_payable_purchase_partial.received_purchase_order.purchase_order.is_additional_disc_from_net == true
        value_after_first_discount - value_after_first_discount * (account_payable_purchase_partial.received_purchase_order.purchase_order.second_discount.to_f / 100)
      elsif account_payable_purchase_partial.received_purchase_order.purchase_order.second_discount.present?
        gross_amount - gross_amount * ((account_payable_purchase_partial.received_purchase_order.purchase_order.first_discount.to_f + account_payable_purchase_partial.received_purchase_order.purchase_order.second_discount.to_f) / 100)
      end
      return value_after_second_discount || value_after_first_discount
    else
      value_after_first_discount = gross_amount - gross_amount * (account_payable_purchase_partial.received_purchase_order.direct_purchase.first_discount.to_f / 100)
      value_after_second_discount = if account_payable_purchase_partial.received_purchase_order.direct_purchase.is_additional_disc_from_net == true
        value_after_first_discount - value_after_first_discount * (account_payable_purchase_partial.received_purchase_order.direct_purchase.second_discount.to_f / 100)
      elsif account_payable_purchase_partial.received_purchase_order.direct_purchase.second_discount.present?
        gross_amount - gross_amount * ((account_payable_purchase_partial.received_purchase_order.direct_purchase.first_discount.to_f + account_payable_purchase_partial.received_purchase_order.direct_purchase.second_discount.to_f) / 100)
      end
      return value_after_second_discount || value_after_first_discount
    end
  end
  
  def get_vat_in_money_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount)
    value_after_discount_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount) * 0.1
  end
  
  def value_after_discount_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount)
    if purchase_type.eql?("order")
      value_after_first_discount = gross_amount - gross_amount * (account_payable_purchase_partial.received_purchase_order.purchase_order.first_discount.to_f / 100)
      value_after_second_discount = if account_payable_purchase_partial.received_purchase_order.purchase_order.is_additional_disc_from_net == true
        value_after_first_discount - value_after_first_discount * (account_payable_purchase_partial.received_purchase_order.purchase_order.second_discount.to_f / 100)
      elsif account_payable_purchase_partial.received_purchase_order.purchase_order.second_discount.present?
        gross_amount - gross_amount * ((account_payable_purchase_partial.received_purchase_order.purchase_order.first_discount.to_f + account_payable_purchase_partial.received_purchase_order.purchase_order.second_discount.to_f) / 100)
      end
      return value_after_second_discount || value_after_first_discount
    else
      value_after_first_discount = gross_amount - gross_amount * (account_payable_purchase_partial.received_purchase_order.direct_purchase.first_discount.to_f / 100)
      value_after_second_discount = if account_payable_purchase_partial.received_purchase_order.direct_purchase.is_additional_disc_from_net == true
        value_after_first_discount - value_after_first_discount * (account_payable_purchase_partial.received_purchase_order.direct_purchase.second_discount.to_f / 100)
      elsif account_payable_purchase_partial.received_purchase_order.direct_purchase.second_discount.present?
        gross_amount - gross_amount * ((account_payable_purchase_partial.received_purchase_order.direct_purchase.first_discount.to_f + account_payable_purchase_partial.received_purchase_order.direct_purchase.second_discount.to_f) / 100)
      end
      return value_after_second_discount || value_after_first_discount
    end
  end
  
  def value_after_ppn_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount)
    vat_type = if purchase_type.eql?("order")
      account_payable_purchase_partial.received_purchase_order.purchase_order.value_added_tax
    else
      account_payable_purchase_partial.received_purchase_order.direct_purchase.vat_type
    end
    if vat_type.eql?("exclude")
      value_after_discount_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount) + get_vat_in_money_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount)
    else
      value_after_discount_for_ap_payment_partial(account_payable_purchase_partial, purchase_type, gross_amount)
    end
  end
end
