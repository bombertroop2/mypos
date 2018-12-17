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
      return [
        { coa_id:   11,
          is_debit: true,
          total: self.price},
        { coa_id: warehouse.coa_id,
          is_debit: false,
          total: self.price}
      ]

    end
  end

  def update_record_data_accounting
    transcation = AccountingJurnalTransction.find_by_model(self)
    if self.class == CashDisbursement
      transcation.update(description: check_description_is_exits?)
      transcation.details.update_all(saldo: self.price)
    end
  end
end
