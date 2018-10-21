class AddSomeFieldsToBeginningStockProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :beginning_stock_products, :quantity, :integer, default: 0
    add_column :beginning_stock_products, :import_date, :date
    add_reference :beginning_stock_products, :warehouse, index: true, foreign_key: true
    add_reference :beginning_stock_products, :size, index: true, foreign_key: true
    add_reference :beginning_stock_products, :color, index: true
    add_foreign_key :beginning_stock_products, :common_fields, column: :color_id
    add_index :beginning_stock_products, [:warehouse_id, :product_id, :color_id, :size_id], unique: true, name: "index_bsp_on_warehouse_id_product_id_color_id_size_id"
  end
end
