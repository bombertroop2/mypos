class AddUniqueIndexToCounterEventWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_index :counter_event_warehouses, [:counter_event_id, :warehouse_id], unique: true, name: "index_cew_on_counter_event_id_and_warehouse_id"
  end
end
