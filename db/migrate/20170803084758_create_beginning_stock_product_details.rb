class CreateBeginningStockProductDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :beginning_stock_product_details do |t|
      t.integer :beginning_stock_product_id
      t.references :color, foreign_key: true
      t.references :size, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
    add_foreign_key :beginning_stock_product_details, :beginning_stock_products, column: :beginning_stock_product_id
    add_index :beginning_stock_product_details, :beginning_stock_product_id, name: "index_bspd_on_beginning_stock_product_id"
  end
end
