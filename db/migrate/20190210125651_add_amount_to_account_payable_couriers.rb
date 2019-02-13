class AddAmountToAccountPayableCouriers < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payable_couriers, :amount, :decimal, default: 0
  end
end
