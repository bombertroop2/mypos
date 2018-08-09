class AddTransactionDateToJournal < ActiveRecord::Migration[5.0]
  def change
    add_column :journals, :transaction_date, :date
    add_index :journals, :transaction_date
    remove_index :journals, [:transactionable_type, :transactionable_id]
    add_index :journals, [:transactionable_type, :transactionable_id]
    remove_index :journals, :fiscal_is_closed?
    remove_column :journals, :fiscal_is_closed?, :boolean
  end
end
