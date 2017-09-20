class CreateEventWarehouses < ActiveRecord::Migration[5.0]
  def change
    create_table :event_warehouses do |t|
      t.references :event, foreign_key: true
      t.references :warehouse, foreign_key: true

      t.timestamps
    end
  end
end
