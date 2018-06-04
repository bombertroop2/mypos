class CreateConsignmentSaleProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :consignment_sale_products do |t|
      t.references :consignment_sale, foreign_key: true
      t.references :product_barcode, foreign_key: true
      t.references :price_list, foreign_key: true
      t.decimal :total

      t.timestamps
    end
  end
end
