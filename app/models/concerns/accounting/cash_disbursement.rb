require 'active_support/concern'

module Accounting::CashDisbursement
  extend ActiveSupport::Concern
  include Accounting::CurrentSaldo

  included do
    has_one :warehouse, through: :cashier_opening
    has_one :coa, class_name: "AccountingAccount", foreign_key: :coa_id, through: :warehouse
  end

end
