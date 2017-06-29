class AddUniqueIndexToStockProducts < ActiveRecord::Migration[5.0]
  def change
    add_index :stock_products, [:stock_id, :product_id], unique: true
  end
end
