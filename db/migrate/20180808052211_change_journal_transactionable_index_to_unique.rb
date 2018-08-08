class ChangeJournalTransactionableIndexToUnique < ActiveRecord::Migration[5.0]
  def change
    remove_index :journals, [:transactionable_type, :transactionable_id]
    add_index :journals, [:transactionable_type, :transactionable_id], unique: true
  end
end
