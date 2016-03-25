class RemoveFieldsFromProductDetails < ActiveRecord::Migration
  def change
    remove_reference :product_details, :color, index: true, foreign_key: true
    remove_reference :product_details, :product_price_code, index: true, foreign_key: true
  end
end
