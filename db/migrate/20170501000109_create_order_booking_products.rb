class CreateOrderBookingProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :order_booking_products do |t|
      t.references :order_booking, foreign_key: true
      t.references :product, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
