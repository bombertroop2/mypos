require 'active_support/concern'

module Accounting::TransactionCashIn
  extend ActiveSupport::Concern
  include Accounting::Transaction

  included do
    after_save    :save_record_data_accounting
  end

  protected
  #

  def save_record_data_accounting
    set_record_data_accounting("cashin")
  end

end
