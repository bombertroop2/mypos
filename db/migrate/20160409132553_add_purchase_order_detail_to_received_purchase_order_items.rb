class AddPurchaseOrderDetailToReceivedPurchaseOrderItems < ActiveRecord::Migration
  def change
    add_reference :received_purchase_order_items, :purchase_order_detail, foreign_key: true
    add_index :received_purchase_order_items, :purchase_order_detail_id, name: 'received_purchase_order_detail_index'
  end
end
