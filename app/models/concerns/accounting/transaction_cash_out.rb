require 'active_support/concern'

module Accounting::TransactionCashOut
  extend ActiveSupport::Concern
  include Accounting::Transaction

  included do
    after_save        :save_record_data_accounting
    before_destroy    :remove_record
  end

  protected
  #

  def save_record_data_accounting
    set_record_data_accounting("cashout")
  end

  def remove_record
    destroy_transaction("cashout")
  end

end
