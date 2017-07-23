class CreateStockMovementWarehouses < ActiveRecord::Migration[5.0]
  def change
    create_table :stock_movement_warehouses do |t|
      t.references :stock_movement_month, foreign_key: true
      t.references :warehouse, foreign_key: true

      t.timestamps
    end
  end
end
