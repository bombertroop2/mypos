require 'active_support/concern'

module Accounting::TransactionCashIn
  extend ActiveSupport::Concern
  include Accounting::Transaction
end
