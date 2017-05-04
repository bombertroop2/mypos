class AddNumberToOrderBooking < ActiveRecord::Migration[5.0]
  def change
    add_column :order_bookings, :number, :string
  end
end
