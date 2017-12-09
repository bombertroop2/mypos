class AddIsActiveToEventWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_column :event_warehouses, :is_active, :boolean
  end
end
