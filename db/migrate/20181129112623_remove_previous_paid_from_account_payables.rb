class RemovePreviousPaidFromAccountPayables < ActiveRecord::Migration[5.0]
  def change
    remove_column :account_payables, :previous_paid, :decimal
  end
end
