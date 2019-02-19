class AddUniqueIndexOnNumberToAccountPayablePayments < ActiveRecord::Migration[5.0]
  def change
    add_index :account_payable_payments, :number, unique: true
  end
end
