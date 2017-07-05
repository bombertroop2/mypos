class AddUniqueIndexToShipmentOrderBookingId < ActiveRecord::Migration[5.0]
  def change
    remove_index :shipments, :order_booking_id if index_exists?(:shipments, :order_booking_id)
    add_foreign_key :shipments, :order_bookings unless foreign_key_exists?(:shipments, :order_bookings)
    add_index :shipments, :order_booking_id, :unique => true
  end
end
