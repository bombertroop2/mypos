class RemoveAmountFromAccountPayableCouriers < ActiveRecord::Migration[5.0]
  def change
    remove_column :account_payable_couriers, :amount, :decimal
  end
end
