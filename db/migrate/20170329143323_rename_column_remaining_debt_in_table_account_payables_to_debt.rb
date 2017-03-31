class RenameColumnRemainingDebtInTableAccountPayablesToDebt < ActiveRecord::Migration[5.0]
  def change
rename_column :account_payables, :remaining_debt, :debt
  end
end
