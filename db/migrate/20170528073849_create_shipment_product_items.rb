class CreateShipmentProductItems < ActiveRecord::Migration[5.0]
  def change
    create_table :shipment_product_items do |t|
      t.references :order_booking_product_item, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
