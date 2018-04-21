class CreateCounterEventWarehouses < ActiveRecord::Migration[5.0]
  def change
    create_table :counter_event_warehouses do |t|
      t.integer :counter_event_id
      t.integer :warehouse_id
      t.boolean :is_active, default: false

      t.timestamps
    end
  end
end
