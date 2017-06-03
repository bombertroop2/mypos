class AddAvailableQuantityToOrderBookingProductItems < ActiveRecord::Migration[5.0]
  def change
    add_column :order_booking_product_items, :available_quantity, :integer, default: 0
  end
end
