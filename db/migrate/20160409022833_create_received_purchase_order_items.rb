class CreateReceivedPurchaseOrderItems < ActiveRecord::Migration
  def change
    create_table :received_purchase_order_items do |t|
      t.references :size, index: true, foreign_key: true
      t.references :color, index: true
      t.references :received_purchase_order_product, foreign_key: true
      t.integer :quantity

      t.timestamps null: false
    end
    add_index :received_purchase_order_items, :received_purchase_order_product_id, name: 'received_purchase_order_product_items_index'
    add_foreign_key :received_purchase_order_items, :common_fields, column: :color_id
  end
end
