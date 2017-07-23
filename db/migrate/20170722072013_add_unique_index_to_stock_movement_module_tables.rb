class AddUniqueIndexToStockMovementModuleTables < ActiveRecord::Migration[5.0]
  def change
    add_index :stock_movements, :year, :unique => true
    add_index :stock_movement_months, [:month, :stock_movement_id], :unique => true
    add_index :stock_movement_warehouses, [:stock_movement_month_id, :warehouse_id], :unique => true, name: "index_smw_on_stock_movement_month_id_and_warehouse_id"
    add_index :stock_movement_products, [:product_id, :stock_movement_warehouse_id], :unique => true, name: "index_smp_on_product_id_and_stock_movement_warehouse_id"
    add_index :stock_movement_product_details, [:stock_movement_product_id, :color_id, :size_id], :unique => true, name: "index_smpd_on_stock_movement_product_id_color_id_size_id"
  end
end
