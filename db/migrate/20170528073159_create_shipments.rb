class CreateShipments < ActiveRecord::Migration[5.0]
  def change
    create_table :shipments do |t|
      t.string :delivery_order_number
      t.date :delivery_date
      t.date :received_date
      t.references :order_booking, foreign_key: true
      t.integer :quantity
      t.references :courier, foreign_key: true
      t.integer :created_by, index: true

      t.timestamps
    end
  end
end
