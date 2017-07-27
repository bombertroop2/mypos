class RemoveSomeColumnsFromStockMovementProductDetails < ActiveRecord::Migration[5.0]
  def change
    remove_column :stock_movement_product_details, :purchase_order_quantity_received, :integer
    remove_column :stock_movement_product_details, :purchase_return_quantity_returned, :integer
    remove_column :stock_movement_product_details, :delivery_order_quantity_received, :integer
    remove_column :stock_movement_product_details, :delivery_order_quantity_delivered, :integer
    remove_column :stock_movement_product_details, :stock_return_quantity_returned, :integer
    remove_column :stock_movement_product_details, :stock_transfer_quantity_received, :integer
    remove_column :stock_movement_product_details, :stock_transfer_quantity_delivered, :integer
    remove_column :stock_movement_product_details, :last_transaction_date, :date
    remove_column :stock_movement_product_details, :stock_return_quantity_received, :integer
  end
end
