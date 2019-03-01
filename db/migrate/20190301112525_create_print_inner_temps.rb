class CreatePrintInnerTemps < ActiveRecord::Migration[5.0]
  def change
    create_table :print_inner_temps do |t|
      t.string :warehouse_name
      t.string :warehouse_code
      t.string :order_booking_number
      t.date :plan_date
      t.text :note
      t.integer :colly
      t.integer :quantity
      t.string :hostname

      t.timestamps
    end
  end
end
