class RemoveSomeFieldsFromAccountPayables < ActiveRecord::Migration[5.0]
  def change
    remove_column :account_payables, :amount_of_debt, :decimal
    remove_column :account_payables, :amount_to_be_paid, :decimal
  end
end
