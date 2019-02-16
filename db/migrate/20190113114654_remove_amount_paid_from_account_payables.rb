class RemoveAmountPaidFromAccountPayables < ActiveRecord::Migration[5.0]
  def change
    remove_column :account_payables, :amount_paid, :decimal
  end
end
