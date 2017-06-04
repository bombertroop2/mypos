class ChangePrintDateColumnOnOrderBookings < ActiveRecord::Migration[5.0]
  def change
    change_column :order_bookings, :print_date, :datetime
  end
end
