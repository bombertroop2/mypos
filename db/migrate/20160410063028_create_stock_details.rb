class CreateStockDetails < ActiveRecord::Migration
  def change
    create_table :stock_details do |t|
      t.references :stock_product, index: true, foreign_key: true
      t.references :size, index: true, foreign_key: true
      t.references :color, index: true
      t.integer :quantity

      t.timestamps null: false
    end
    add_foreign_key :stock_details, :common_fields, column: :color_id
  end
end
