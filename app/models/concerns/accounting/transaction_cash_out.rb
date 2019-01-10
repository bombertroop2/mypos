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


# hide cost di receiving
# bisa revisi warehouse gudang di PO
# tambahkan no invoice supplier dan tanggal invoice supplier di AP invoice
# tambahkan general var untuk menentukan pencatatan hutang (ketika receiving atau AP invoice)
# due date AP invoice ???? TOP vendor
# AP payment tampilkan AP invoice yang due date
# tambahkan over due report AP invoice
# tambahkan bank detail di vendor account no, account name, branch code, bank code, bank address, swift code (googling untuk max digit)
# tambahkan retial price di shipment/DO
# tambahkan payment gateway di master bank
# tambahkan EDC di POS (free text)
# settlement
