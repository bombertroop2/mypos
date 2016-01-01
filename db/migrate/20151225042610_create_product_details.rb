class CreateProductDetails < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists? 'product_details'
      create_table :product_details do |t|
        t.references :product, index: true, foreign_key: true
        t.references :size, index: true, foreign_key: true
        t.decimal :cost
        t.decimal :price
        t.string :barcode
        t.references :color, index: true, foreign_key: true

        t.timestamps null: false
      end
    end
  end
end
