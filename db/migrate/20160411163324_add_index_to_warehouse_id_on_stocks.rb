class AddIndexToWarehouseIdOnStocks < ActiveRecord::Migration
  def change
    remove_index :stocks, :warehouse_id
    add_index :stocks, :warehouse_id, :unique => true
  end
end
