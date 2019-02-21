class AddPriceListIdToShipmentProductItems < ActiveRecord::Migration[5.0]
  def change
    add_reference :shipment_product_items, :price_list, foreign_key: true
  end
end
