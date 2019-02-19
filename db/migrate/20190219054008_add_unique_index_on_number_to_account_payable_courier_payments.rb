class AddUniqueIndexOnNumberToAccountPayableCourierPayments < ActiveRecord::Migration[5.0]
  def change
    add_index :account_payable_courier_payments, :number, unique: true
  end
end
