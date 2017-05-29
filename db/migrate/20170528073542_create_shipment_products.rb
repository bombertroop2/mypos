class CreateShipmentProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :shipment_products do |t|
      t.references :order_booking_product, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
