class CreateStockMovementMonths < ActiveRecord::Migration[5.0]
  def change
    create_table :stock_movement_months do |t|
      t.integer :month
      t.references :stock_movement, foreign_key: true

      t.timestamps
    end
  end
end
