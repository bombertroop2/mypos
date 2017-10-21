class RemoveBarcodeFromProductDetails < ActiveRecord::Migration[5.0]
  def change
    remove_column :product_details, :barcode, :string
  end
end
