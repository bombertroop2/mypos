require 'active_support/concern'

module Accounting::Transaction::Shipment
  def set_account_shipment
    acc = []
    acc << { coa_id:   24,
      is_debit: true,
      total: (self.amount_paid + self.amount_returned)}
    acc << { coa_id:   18,
      is_debit: false,
      total: self.amount_paid}
  end
end
