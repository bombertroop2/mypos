require 'active_support/concern'

module Accounting::Transaction::Invoice
  def set_account_payable
    acc = []
    acc << { coa_id:   18,
      is_debit: true,
      total: self.amount_paid}
    acc << { coa_id:   3,
      is_debit: false,
      total: self.amount_paid}

    return acc
  end
end
