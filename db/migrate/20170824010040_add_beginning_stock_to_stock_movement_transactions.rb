class AddBeginningStockToStockMovementTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_movement_transactions, :beginning_stock, :integer, default: 0
  end
end
