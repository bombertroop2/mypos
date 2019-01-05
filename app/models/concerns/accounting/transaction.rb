require 'active_support/concern'

module Accounting::Transaction
  include Accounting::Transaction::PurchaseOrder
  include Accounting::Transaction::Invoice
  include Accounting::Transaction::Shipment


  def destroy_transaction(type_jurnal)
    AccountingJurnalTransction.where(model_id: self.id, model_type: self.class.to_s).first.destroy
  end

  def set_record_data_accounting(type_jurnal)
    if !(transcation = self.check_transaction_is_exits?(type_jurnal) ).present?
      transcation = AccountingJurnalTransction.new({
        type_jurnal:  type_jurnal,
        model_type:   self.class.to_s,
        model_id:     self.id,
        description:  check_description_is_exits?,
        warehouse_id: (self.warehouse.id rescue nil)
      })
    else
      transcation.details.destroy_all
    end
    transcation.set_detail_record_transaction(self)
    transcation.save if transcation.details.present?
  end

  def check_transaction_is_exits?(type_jurnal)
    AccountingJurnalTransction.where(model_id: self.id, model_type: self.class.to_s, type_jurnal: type_jurnal).first
  end

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
    if self.class.to_s == "CashDisbursement"
      return [ { coa_id:   11,
        is_debit: true,
        total: self.price},
        { coa_id: self.warehouse.coa_id,
          is_debit: false,
          total: self.price}
        ]
      #
    elsif "DirectPurchase".eql?(self.class.to_s)
      return set_purchase
    elsif "PurchaseOrder".eql?(self.class.to_s)
      return !self.status.eql?("Open") ? set_purchase : []
    elsif "AccountPayable".eql?(self.class.to_s)
      set_account_payable
    end
  end

end
