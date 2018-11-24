class AddAdjustmentInQuantityToStockMovementTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_movement_transactions, :adjustment_in_quantity, :integer, default: 0
  end
end
