module AccountPayableCouriersHelper
  def get_include_vat_in_money_for_ap_invoice_courier(gross_amount)
    (gross_amount / 1.1 * 0.1).round(2)
  end
  
  def get_vat_in_money_for_ap_invoice_courier(gross_amount)
    gross_amount * 0.1
  end
  
  def value_after_ppn_for_ap_invoice_courier(packing_list, gross_amount)
    if packing_list.courier_vat_type.eql?("exclude")
      gross_amount + get_vat_in_money_for_ap_invoice_courier(gross_amount)
    else
      gross_amount
    end
  end
end
