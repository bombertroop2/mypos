class CreateShipmentReceiptProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :shipment_receipt_products do |t|
      t.references :shipment_receipt, foreign_key: true
      t.references :shipment_product, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
