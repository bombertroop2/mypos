class AddPriceCodeToProductDetails < ActiveRecord::Migration
  def change
    add_reference :product_details, :price_code, index: true
    add_foreign_key :product_details, :common_fields, column: :price_code_id

  end
end
