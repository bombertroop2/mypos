class AddUniqueIndexToOrderBookingProductItems < ActiveRecord::Migration[5.0]
  def change
    add_index :order_booking_product_items, [:order_booking_product_id, :size_id, :color_id], unique: true, name: "index_obpi_on_obp_id_and_size_id_and_color_id"
  end
end
