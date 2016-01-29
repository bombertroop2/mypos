class CreatePurchaseOrderDetails < ActiveRecord::Migration
  def change
    create_table :purchase_order_details do |t|
      t.references :product_detail, index: true, foreign_key: true
      t.integer :quantity
      t.decimal :total_unit_price
      t.integer :receiving_qty
      t.date :delivery_date
      t.references :purchase_order_product, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
