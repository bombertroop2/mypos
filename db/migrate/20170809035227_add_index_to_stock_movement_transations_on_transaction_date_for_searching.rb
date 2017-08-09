class AddIndexToStockMovementTransationsOnTransactionDateForSearching < ActiveRecord::Migration[5.0]
  def change
    add_index :stock_movement_transactions, :transaction_date
  end
end
