class AddSkuToWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_column :warehouses, :sku, :string
    add_index :warehouses, :sku, unique: true
  end
end
