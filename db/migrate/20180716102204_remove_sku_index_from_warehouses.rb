class RemoveSkuIndexFromWarehouses < ActiveRecord::Migration[5.0]
  def change
    remove_index :warehouses, :sku
  end
end
