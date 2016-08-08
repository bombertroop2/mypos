class RemoveFieldsFromProductDetails < ActiveRecord::Migration
  def change
    remove_reference :product_details, :common_field, column: :color_id, index: true, foreign_key: true
    remove_reference :product_details, :product_price_code, index: true, foreign_key: true if ActiveRecord::Base.connection.table_exists? 'product_price_codes'
  end
end
