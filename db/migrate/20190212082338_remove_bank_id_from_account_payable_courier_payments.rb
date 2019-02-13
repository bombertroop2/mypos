class RemoveBankIdFromAccountPayableCourierPayments < ActiveRecord::Migration[5.0]
  def change
    remove_reference :account_payable_courier_payments, :bank, foreign_key: true
  end
end
