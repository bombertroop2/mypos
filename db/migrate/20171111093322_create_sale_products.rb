class CreateSaleProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :sale_products do |t|
      t.references :sale, foreign_key: true
      t.references :product_barcode, foreign_key: true
      t.integer :quantity
      t.decimal :total

      t.timestamps
    end
    add_index :sale_products, [:sale_id, :product_barcode_id], unique: true
  end
end
