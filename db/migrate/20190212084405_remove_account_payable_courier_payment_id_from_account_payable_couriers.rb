class RemoveAccountPayableCourierPaymentIdFromAccountPayableCouriers < ActiveRecord::Migration[5.0]
  def change
    remove_reference :account_payable_couriers, :account_payable_courier_payment, foreign_key: true
  end
end
