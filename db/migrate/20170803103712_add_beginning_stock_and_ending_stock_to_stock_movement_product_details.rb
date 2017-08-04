class AddBeginningStockAndEndingStockToStockMovementProductDetails < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_movement_product_details, :beginning_stock, :integer, default: 0
    add_column :stock_movement_product_details, :ending_stock, :integer, default: 0
  end
end
