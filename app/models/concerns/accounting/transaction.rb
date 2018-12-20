require 'active_support/concern'

module Accounting::Transaction


  def check_description_is_exits?
    if self.attributes.keys.include?("description")
      return self.description
    elsif self.attributes.keys.include?("number")
      return self.number
    else
      return self.model_name.human
    end
    return "Unknow Transction"
  end

  def set_detail_coa_jurnal
    if self.class == CashDisbursement
      return [ { coa_id:   11,
        is_debit: true,
        total: self.price},
        { coa_id: self.warehouse.coa_id,
          is_debit: false,
          total: self.price}
        ]
      #
    elsif [PurchaseOrder,  DirectPurchase].include?(self.class)
      if self.status.eql?("Finish")
        return set_purchase
      end
    end
  end

# ========================= Purchase =========================
  def set_purchase
    acc                     = []
    discs                   = get_discount_purchase_order
    total_purchase          = self.net_amount.to_f
    tax_purchase            = self.net_amount.to_f * 0.1
    total_purchase_whit_tax = total_purchase + tax_purchase
    total                   = total_purchase_whit_tax

    discs.each_with_index do |i, disc|
      if disc != 0.0
        discs[i] = total_purchase_whit_tax / 100 * disc
        total -= discs[i]
      end
    end

    acc << { coa_id:   7,
      is_debit: true,
      total: total}
    #
    discs.each do |disc|
      if disc != 0.0
        acc << { coa_id:   5,
          is_debit: true,
          total: disc}
      end
    end

    acc << { coa_id: 18,
      is_debit: false,
      total: total_purchase}

    acc << { coa_id: 14,
      is_debit: false,
      total: tax_purchase}
    #
    return acc
  end

  def get_price_purchase_order
    if self.class == PurchaseOrder
      self.net_amount.to_f
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

# ========================= Purchase END =========================

  def update_saldo
    if self.class == CashDisbursement
    end
  end

  def update_record_data_accounting
    transcation = AccountingJurnalTransction.find_by_model(self)
    if self.class == CashDisbursement
      transcation.update(description: check_description_is_exits?)
      transcation.details.update_all(total: self.price)
    end
  end
end
