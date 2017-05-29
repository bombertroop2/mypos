class AddShipmentIdToShipmentProducts < ActiveRecord::Migration[5.0]
  def change
    add_reference :shipment_products, :shipment, foreign_key: true
  end
end
