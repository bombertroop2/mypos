class AddIndexToStockMovementProductDetailsOnStockMovementProductId < ActiveRecord::Migration[5.0]
  def change
    add_index :stock_movement_product_details, :stock_movement_product_id, name: "index_smpd_on_stock_movement_product_id"
  end
end
