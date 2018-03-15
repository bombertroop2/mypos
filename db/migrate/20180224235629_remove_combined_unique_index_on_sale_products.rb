class RemoveCombinedUniqueIndexOnSaleProducts < ActiveRecord::Migration[5.0]
  def change
    remove_index :sale_products, column: [:sale_id, :product_barcode_id]
  end
end
