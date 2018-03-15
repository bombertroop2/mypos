class AddSoldQuantityToStockMovementTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_movement_transactions, :sold_quantity, :integer, default: 0
  end
end
