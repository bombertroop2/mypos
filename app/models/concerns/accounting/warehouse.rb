require 'active_support/concern'

module Accounting::Warehouse
  extend ActiveSupport::Concern
  include Accounting::CurrentSaldo
  included do
    belongs_to  :coa,     class_name: "AccountingAccount", foreign_key: :coa_id
    has_many :cash_disbursements, through: :cashier_openings
    validates   :coa_id,  presence: true
  end

  def code_category_cash
  end

  def real_saldo
    current_saldo.to_f - cash_disbursements.sum(&:price).to_f
  end
end
