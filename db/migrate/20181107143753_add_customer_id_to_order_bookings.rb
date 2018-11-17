class AddCustomerIdToOrderBookings < ActiveRecord::Migration[5.0]
  def change
    add_reference :order_bookings, :customer, index: true, foreign_key: true
  end
end
