class CreateStockMovementProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :stock_movement_products do |t|
      t.references :product, foreign_key: true
      t.references :stock_movement_warehouse, foreign_key: true

      t.timestamps
    end
  end
end
