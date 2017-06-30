class CreateStockMutations < ActiveRecord::Migration[5.0]
  def change
    create_table :stock_mutations do |t|
      t.date :delivery_date
      t.date :received_date
      t.integer :quantity
      t.references :courier, foreign_key: true
      t.references :origin_warehouse, index: true
      t.string :number
      t.references :destination_warehouse, index: true

      t.timestamps
    end
    add_foreign_key :stock_mutations, :warehouses, column: :origin_warehouse_id
    add_foreign_key :stock_mutations, :warehouses, column: :destination_warehouse_id
  end
end
