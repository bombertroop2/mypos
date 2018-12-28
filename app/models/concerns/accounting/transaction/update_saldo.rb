require 'active_support/concern'

module Accounting::Transaction::UpdateSaldo
  def update_saldo
    if self.class.to_s == "CashDisbursement"
    end
  end
end
