class CreateOrderBookings < ActiveRecord::Migration[5.0]
  def change
    create_table :order_bookings do |t|
      t.date :plan_date
      t.references :origin_warehouse, foreign_key: true
      t.references :destination_warehouse, foreign_key: true
      t.date :print_date
      t.text :note

      t.timestamps
    end
  end
end
