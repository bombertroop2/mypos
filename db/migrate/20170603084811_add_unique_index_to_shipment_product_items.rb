class AddUniqueIndexToShipmentProductItems < ActiveRecord::Migration[5.0]
  def change
    add_index :shipment_product_items, [:order_booking_product_item_id, :shipment_product_id], unique: true, name: "index_shipment_product_items_on_obpi_and_shipment_product_id"
  end
end
