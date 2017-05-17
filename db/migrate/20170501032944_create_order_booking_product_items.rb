class CreateOrderBookingProductItems < ActiveRecord::Migration[5.0]
  def change
    create_table :order_booking_product_items do |t|
      t.references :order_booking_product, foreign_key: true
      t.references :size, foreign_key: true
      t.references :color, index: true
      t.integer :quantity

      t.timestamps
    end
    add_foreign_key :order_booking_product_items, :common_fields, column: :color_id
  end
end
