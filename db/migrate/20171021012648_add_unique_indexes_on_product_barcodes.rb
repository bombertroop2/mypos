class AddUniqueIndexesOnProductBarcodes < ActiveRecord::Migration[5.0]
  def change
    add_index :product_barcodes, :barcode, unique: true
    add_index :product_barcodes, [:product_color_id, :size_id], unique: true
  end
end
