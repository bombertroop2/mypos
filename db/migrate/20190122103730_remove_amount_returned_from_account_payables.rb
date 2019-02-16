class RemoveAmountReturnedFromAccountPayables < ActiveRecord::Migration[5.0]
  def change
    remove_column :account_payables, :amount_returned, :decimal
  end
end
