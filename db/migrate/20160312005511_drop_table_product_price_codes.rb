class DropTableProductPriceCodes < ActiveRecord::Migration
  def change
    drop_table :product_price_codes if ActiveRecord::Base.connection.table_exists? 'product_price_codes'
  end
end
