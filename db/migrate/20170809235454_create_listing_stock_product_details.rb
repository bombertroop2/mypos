class CreateListingStockProductDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :listing_stock_product_details do |t|
      t.references :listing_stock, foreign_key: true, index: true
      t.references :color, index: true
      t.references :size, foreign_key: true, index: true

      t.timestamps
    end
    add_index :listing_stock_product_details, [:listing_stock_id, :color_id, :size_id], unique: true, name: "index_lspd_on_listing_stock_id_and_color_id_and_size_id"
    add_foreign_key :listing_stock_product_details, :common_fields, column: :color_id
  end
end
