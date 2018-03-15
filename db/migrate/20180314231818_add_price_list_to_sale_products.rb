class AddPriceListToSaleProducts < ActiveRecord::Migration[5.0]
  def change
    add_reference :sale_products, :price_list, foreign_key: true
  end
end
