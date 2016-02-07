class RemoveSomeFieldsFromProductDetails < ActiveRecord::Migration
  def change
    remove_column :product_details, :product_id
    remove_column :product_details, :price_code_id
    add_reference :product_details, :product_price_code, index: true
  end
end
