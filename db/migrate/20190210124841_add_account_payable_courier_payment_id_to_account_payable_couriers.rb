class AddAccountPayableCourierPaymentIdToAccountPayableCouriers < ActiveRecord::Migration[5.0]
  def change
    add_reference :account_payable_couriers, :account_payable_courier_payment, foreign_key: true, index: false
    add_index :account_payable_couriers, :account_payable_courier_payment_id, name: "index_apc_on_account_payable_courier_payment_id"
  end
end
