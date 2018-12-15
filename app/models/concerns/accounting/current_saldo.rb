require 'active_support/concern'

module Accounting::CurrentSaldo
  def current_saldo
    coa.saldos.where(year: Date.today.year).first
  end
end
