class AddUniqueIndexToPurchaseReturnProducts < ActiveRecord::Migration[5.0]
  def change
    add_index :purchase_return_products, [:purchase_return_id, :purchase_order_product_id], unique: true, name: "index_prp_on_purchase_return_id_and_purchase_order_product_id"
    add_index :purchase_return_products, [:purchase_return_id, :direct_purchase_product_id], unique: true, name: "index_prp_on_purchase_return_id_and_direct_purchase_product_id"
  end
end
