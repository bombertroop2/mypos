class CreateProductPriceCodes < ActiveRecord::Migration
  def change
    create_table :product_price_codes do |t|
      t.references :product, index: true, foreign_key: true
      t.references :price_code, index: true

      t.timestamps null: false
    end
    add_foreign_key :product_price_codes, :common_fields, column: :price_code_id
  end
end
