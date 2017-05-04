class AddStatusToOrderBooking < ActiveRecord::Migration[5.0]
  def change
    add_column :order_bookings, :status, :string, limit: 1
  end
end
