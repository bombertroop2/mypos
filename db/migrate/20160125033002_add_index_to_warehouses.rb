class AddIndexToWarehouses < ActiveRecord::Migration
  def change
    add_index :warehouses, :code, :unique => true
  end
end
