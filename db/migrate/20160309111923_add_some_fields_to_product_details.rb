class AddSomeFieldsToProductDetails < ActiveRecord::Migration
  def change
    add_reference :product_details, :product, index: true, foreign_key: true
    add_reference :product_details, :price_code, index: true, foreign_key: true
  end
end
