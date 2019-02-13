module AccountPayableCourierPaymentsHelper
  def value_after_ppn_for_ap_invoice_courier_payment(account_payable_courier_payment_invoice, gross_amount)
    if account_payable_courier_payment_invoice.courier_vat_type.eql?("exclude")
      gross_amount + get_vat_in_money_for_ap_invoice_courier(gross_amount)
    else
      gross_amount
    end
  end
end
