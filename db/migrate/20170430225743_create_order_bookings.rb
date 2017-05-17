class CreateOrderBookings < ActiveRecord::Migration[5.0]
  def change
    create_table :order_bookings do |t|
      t.date :plan_date
      t.references :origin_warehouse, index: true
      t.references :destination_warehouse, index: true
      t.date :print_date
      t.text :note

      t.timestamps
    end
    add_foreign_key :order_bookings, :warehouses, column: :origin_warehouse_id
    add_foreign_key :order_bookings, :warehouses, column: :destination_warehouse_id
  end
end
