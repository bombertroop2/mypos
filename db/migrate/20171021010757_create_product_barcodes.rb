class CreateProductBarcodes < ActiveRecord::Migration[5.0]
  def change
    create_table :product_barcodes do |t|
      t.references :product_color, foreign_key: true
      t.references :size, foreign_key: true
      t.string :barcode

      t.timestamps
    end
  end
end
