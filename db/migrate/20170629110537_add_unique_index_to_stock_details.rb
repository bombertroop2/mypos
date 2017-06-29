class AddUniqueIndexToStockDetails < ActiveRecord::Migration[5.0]
  def change
    add_index :stock_details, [:stock_product_id, :size_id, :color_id], unique: true, name: "index_stock_details_on_stock_product_id_size_id_color_id"
  end
end
