require 'active_support/concern'

module Accounting::Warehouse
  extend ActiveSupport::Concern
  include Accounting::CurrentSaldo
  included do
    belongs_to  :coa,     class_name: "AccountingAccount", foreign_key: :coa_id
    validates   :coa_id,  presence: true
  end
end
