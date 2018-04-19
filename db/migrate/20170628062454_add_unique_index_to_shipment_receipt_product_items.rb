class AddUniqueIndexToShipmentReceiptProductItems < ActiveRecord::Migration[5.0]
  def change
#    add_index :shipment_receipt_product_items, [:shipment_receipt_product_id, :shipment_product_item_id], unique: true, name: "index_srpi_on_srp_id_and_spi_id"
  end
end
