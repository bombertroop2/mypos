class RemoveTableShipmentReceipts < ActiveRecord::Migration[5.0]
  def change
    drop_table :shipment_receipt_product_items if ActiveRecord::Base.connection.table_exists? 'shipment_receipt_product_items'
    drop_table :shipment_receipt_products if ActiveRecord::Base.connection.table_exists? 'shipment_receipt_products'
    drop_table :shipment_receipts if ActiveRecord::Base.connection.table_exists? 'shipment_receipts'
  end
end
