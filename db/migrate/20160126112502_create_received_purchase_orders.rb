class CreateReceivedPurchaseOrders < ActiveRecord::Migration
  def change
    create_table :received_purchase_orders do |t|
      t.references :purchase_order_product, index: true, foreign_key: true
      t.references :color, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
