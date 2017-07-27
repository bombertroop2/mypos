class AddPurchaseReturnQuantityReturnedToStockMovementTransactions < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_movement_transactions, :purchase_return_quantity_returned, :integer unless column_exists?(:stock_movement_transactions, :purchase_return_quantity_returned)
  end
end
