class CreateShipmentReceiptProductItems < ActiveRecord::Migration[5.0]
  def change
    create_table :shipment_receipt_product_items do |t|
      t.references :shipment_receipt_product, foreign_key: true, index: {name: "index_srpi_on_shipment_receipt_product_id"}
      t.references :shipment_product_item, foreign_key: true, index: {name: "index_srpi_on_shipment_product_item_id"}
      t.integer :quantity

      t.timestamps
    end

  end
end
