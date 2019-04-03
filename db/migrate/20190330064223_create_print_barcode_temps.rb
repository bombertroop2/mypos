class CreatePrintBarcodeTemps < ActiveRecord::Migration[5.0]
  def change
    create_table :print_barcode_temps, id: false, force: true do |t|
      t.string :product_code
      t.string :brand_name
      t.text :product_description
      t.string :barcode
      t.string :size
      t.string :color_name
      t.decimal :price
      t.string :internet_client_address

      t.timestamps
    end
  end
end
