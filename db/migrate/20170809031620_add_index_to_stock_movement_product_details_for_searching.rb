class AddIndexToStockMovementProductDetailsForSearching < ActiveRecord::Migration[5.0]
  def change
    add_index :stock_movement_product_details, [:color_id, :size_id]
  end
end
