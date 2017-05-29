class AddShipmentProductIdToShipmentProductItems < ActiveRecord::Migration[5.0]
  def change
    add_reference :shipment_product_items, :shipment_product, foreign_key: true
  end
end
