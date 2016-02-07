class CreateReceivedPurchaseOrders < ActiveRecord::Migration
  def change
    create_table :received_purchase_orders do |t|
      t.references :purchase_order_product, index: true, foreign_key: true
      t.references :color, index: true

      t.timestamps null: false
    end
    add_foreign_key :received_purchase_orders, :common_fields, column: :color_id
  end
end
