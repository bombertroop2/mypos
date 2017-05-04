class CreateOrderBookingProductItems < ActiveRecord::Migration[5.0]
  def change
    create_table :order_booking_product_items do |t|
      t.references :order_booking_product, foreign_key: true
      t.references :size, foreign_key: true
      t.references :color, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
