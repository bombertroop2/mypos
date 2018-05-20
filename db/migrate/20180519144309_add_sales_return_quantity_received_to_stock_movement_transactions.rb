class AddSalesReturnQuantityReceivedToStockMovementTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_movement_transactions, :sales_return_quantity_received, :integer, default: 0
  end
end
