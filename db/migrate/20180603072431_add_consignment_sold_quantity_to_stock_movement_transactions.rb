class AddConsignmentSoldQuantityToStockMovementTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_movement_transactions, :consignment_sold_quantity, :integer, default: 0
  end
end
