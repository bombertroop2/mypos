class CreatePurchaseOrders < ActiveRecord::Migration
  def change
    create_table :purchase_orders do |t|
      t.string :number
      t.string :po_type
      t.string :status
      t.references :vendor, index: true, foreign_key: true
      t.date :request_delivery_date
      t.decimal :order_value
      t.decimal :receiving_value
      t.integer :means_of_payment
      t.references :warehouse, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
