class AddUniqueIndexToOrderBookingProducts < ActiveRecord::Migration[5.0]
  def change
    add_index :order_booking_products, [:order_booking_id, :product_id], :unique => true, name: "index_obp_on_order_booking_id_and_product_id"
  end
end
