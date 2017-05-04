class AddUniqueIndexToReceivedPurchaseOrderItems < ActiveRecord::Migration[5.0]
  def change
    add_index :received_purchase_order_items, [:received_purchase_order_product_id, :purchase_order_detail_id], unique: true, name: "index_rpoi_on_rpop_id_and_pod_id"
    add_index :received_purchase_order_items, [:received_purchase_order_product_id, :direct_purchase_detail_id], unique: true, name: "index_rpoi_on_rpop_id_and_dpd_id"
  end
end
