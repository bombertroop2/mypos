class AddVendorIdToAccountPayablePayments < ActiveRecord::Migration[5.0]
  def change
    add_reference :account_payable_payments, :vendor, foreign_key: true
  end
end
