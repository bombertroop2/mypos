class AddPurchaseOrderProductToReceivedPurchaseOrderProducts < ActiveRecord::Migration
  def change
    add_reference :received_purchase_order_products, :purchase_order_product, foreign_key: true
    add_index :received_purchase_order_products, :purchase_order_product_id, name: 'received_purchase_order_product_index'
  end
end
