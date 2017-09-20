class AddCombinedUniqueIndexOnEventWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_index :event_warehouses, [:event_id, :warehouse_id], unique: true
  end
end
