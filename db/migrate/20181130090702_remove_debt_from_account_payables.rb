class RemoveDebtFromAccountPayables < ActiveRecord::Migration[5.0]
  def change
    remove_column :account_payables, :debt, :decimal
  end
end
