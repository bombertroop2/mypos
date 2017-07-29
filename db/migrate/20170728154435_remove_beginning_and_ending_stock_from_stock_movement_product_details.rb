class RemoveBeginningAndEndingStockFromStockMovementProductDetails < ActiveRecord::Migration[5.0]
  def change
    remove_column :stock_movement_product_details, :beginning_stock, :integer
    remove_column :stock_movement_product_details, :ending_stock, :integer
  end
end
