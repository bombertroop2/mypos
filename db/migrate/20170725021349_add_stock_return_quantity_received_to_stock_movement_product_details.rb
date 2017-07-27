class AddStockReturnQuantityReceivedToStockMovementProductDetails < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_movement_product_details, :stock_return_quantity_received, :integer
  end
end
