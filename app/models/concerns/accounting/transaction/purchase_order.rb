require 'active_support/concern'

module Accounting::Transaction::PurchaseOrder
  def set_purchase
    acc                     = []
    discs                   = get_discount_purchase_order
    tax_purchase            = get_tax_purchase_order
    total_purchase          = tax_is_include? ? (self.receiving_value.to_f - tax_purchase) : self.receiving_value.to_f
    total_purchase_whit_tax = total_purchase + tax_purchase
    total                   = total_purchase_whit_tax
    total_discounts         = []
    discs.each do |disc|
      if disc != 0
        total_discounts << (total_purchase_whit_tax / 100) * disc
        total -= (total_purchase_whit_tax / 100) * disc
      end
    end

    acc << { coa_id:   7,
      is_debit: true,
      total: total}
    #
    total_discounts.each do |disc|
      if disc != 0.0
        acc << { coa_id:   4,
          is_debit: true,
          total: disc}
        #
      end
    end

    acc << { coa_id: 18,
      is_debit: false,
      total: total_purchase}
    #
    acc << { coa_id: 14,
      is_debit: false,
      total: tax_purchase}
    #
    return acc
  end

  def get_price_purchase_order
    if self.class.to_s == "PurchaseOrder"
      self.receiving_value.to_f
    else
      self.direct_purchase_details.sum(&:total_unit_price).to_f
    end
  end

  def get_discount_purchase_order
    if is_additional_disc_from_net
      return [self.first_discount.to_i, self.second_discount.to_i]
    else
      return [(self.first_discount.to_i + self.second_discount.to_i)]
    end
  end

  def tax_is_include?
    (self.attributes.keys.include?("vat_type") ? self.vat_type : self.value_added_tax).eql?("include")
  end

  def get_tax_purchase_order
    is_taxable_entrepreneur ? (self.receiving_value.to_f * 0.1) : 0
  end
end
