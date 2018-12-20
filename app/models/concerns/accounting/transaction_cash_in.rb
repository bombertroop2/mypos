require 'active_support/concern'

module Accounting::TransactionCashIn
  extend ActiveSupport::Concern
  include Accounting::Transaction

  included do
    after_save    :save_record_data_accounting
    # after_update    :update_record_data_accounting
  end

  protected
  #

  def save_record_data_accounting
    transcation = AccountingJurnalTransction.new({
      type_jurnal:  "cashin",
      model_type:   self.class.to_s,
      model_id:     self.id,
      description:  check_description_is_exits?
    })

    transcation.set_detail_record_transaction(self)
    transcation.save
    # self.update_saldo
  end

end
