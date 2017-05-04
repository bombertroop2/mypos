class AddUniqueIndexToPurchaseReturnItems < ActiveRecord::Migration[5.0]
  def change
    add_index :purchase_return_items, [:purchase_return_product_id, :purchase_order_detail_id], unique: true, name: "index_pri_on_prp_id_and_pod_id"
    add_index :purchase_return_items, [:purchase_return_product_id, :direct_purchase_detail_id], unique: true, name: "index_pri_on_prp_id_and_dpd_id"
  end
end
