class AddUniqueIndexToShipmentReceiptProducts < ActiveRecord::Migration[5.0]
  def change
#    add_index :shipment_receipt_products, [:shipment_receipt_id, :shipment_product_id], unique: true, name: "index_srp_on_shipment_receipt_id_and_shipment_product_id"
  end
end
