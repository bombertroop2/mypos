class AddIndexToStockMovementTransactionsForSearching < ActiveRecord::Migration[5.0]
  def change
    add_index :stock_movement_transactions, [:stock_movement_product_detail_id, :transaction_date], name: "index_smt_on_stock_movement_product_detail_id_transaction_date"
  end
end
