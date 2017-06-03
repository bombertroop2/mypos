class AddUniqueIndexToShipmentProducts < ActiveRecord::Migration[5.0]
  def change
    add_index :shipment_products, [:order_booking_product_id, :shipment_id], unique: true, name: "index_shipment_products_on_obp_id_and_shipment_id"
  end
end
