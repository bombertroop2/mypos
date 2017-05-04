class AddUniqueIndexToOrderBookingNumber < ActiveRecord::Migration[5.0]
  def change
    add_index :order_bookings, :number, :unique => true
  end
end
