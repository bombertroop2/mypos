class AddRemainingDebtToAccountPayables < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payables, :remaining_debt, :decimal, default: 0
  end
end
