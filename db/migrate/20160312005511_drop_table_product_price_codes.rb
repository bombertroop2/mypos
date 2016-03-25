class DropTableProductPriceCodes < ActiveRecord::Migration
  def change
    drop_table :product_price_codes
  end
end
