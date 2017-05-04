class AddQuantityToOrderBooking < ActiveRecord::Migration[5.0]
  def change
    add_column :order_bookings, :quantity, :integer
  end
end
