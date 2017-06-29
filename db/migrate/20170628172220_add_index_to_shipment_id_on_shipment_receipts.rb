class AddIndexToShipmentIdOnShipmentReceipts < ActiveRecord::Migration[5.0]
  def change
    remove_index :shipment_receipts, :shipment_id if index_exists?(:shipment_receipts, :shipment_id)
    add_index :shipment_receipts, :shipment_id, unique: true
  end
end
