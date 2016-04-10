class CreateReceivedPurchaseOrderProducts < ActiveRecord::Migration
  def change
    create_table :received_purchase_order_products do |t|
      t.references :received_purchase_order, foreign_key: true
      t.references :product, index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :received_purchase_order_products, :received_purchase_order_id, name: 'received_purchase_order_products_index'
  end
end
