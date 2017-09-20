class AddCombinedUniqueIndexOnEventProducts < ActiveRecord::Migration[5.0]
  def change
    add_index :event_products, [:event_warehouse_id, :product_id], unique: true
  end
end
