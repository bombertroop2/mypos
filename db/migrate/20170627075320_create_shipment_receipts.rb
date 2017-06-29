class CreateShipmentReceipts < ActiveRecord::Migration[5.0]
  def change
    create_table :shipment_receipts do |t|
      t.date :received_date
      t.references :shipment, foreign_key: true

      t.timestamps
    end
  end
end
