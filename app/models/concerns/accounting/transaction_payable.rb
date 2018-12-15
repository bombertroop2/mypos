require 'active_support/concern'

module Accounting::TransactionPayable
  extend ActiveSupport::Concern
  include Accounting::Transaction

end
