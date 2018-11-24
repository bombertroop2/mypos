class CreateAdjustmentProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :adjustment_products do |t|
      t.references :adjustment, foreign_key: true
      t.references :product, foreign_key: true
      t.integer :quantity, default: 0

      t.timestamps
    end
    add_index :adjustment_products, [:adjustment_id, :product_id], unique: true
  end
end
