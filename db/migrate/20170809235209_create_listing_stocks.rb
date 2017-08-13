class CreateListingStocks < ActiveRecord::Migration[5.0]
  def change
    create_table :listing_stocks do |t|
      t.references :warehouse, foreign_key: true, index: true
      t.references :product, foreign_key: true, index: true

      t.timestamps
    end
    add_index :listing_stocks, [:warehouse_id, :product_id], unique: true
  end
end
