class AddUniqueIndexToReceivedPurchaseOrderProducts < ActiveRecord::Migration[5.0]
  def change
    add_index :received_purchase_order_products, [:received_purchase_order_id, :purchase_order_product_id], unique: true, name: "index_rpop_on_rpo_id_and_pop_id"
    add_index :received_purchase_order_products, [:received_purchase_order_id, :direct_purchase_product_id], unique: true, name: "index_rpop_on_rpo_id_and_dpp_id"
  end
end
