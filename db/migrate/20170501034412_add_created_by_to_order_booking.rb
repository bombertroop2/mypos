class AddCreatedByToOrderBooking < ActiveRecord::Migration[5.0]
  def change
    add_column :order_bookings, :created_by, :integer
    add_index :order_bookings, :created_by
  end
end
