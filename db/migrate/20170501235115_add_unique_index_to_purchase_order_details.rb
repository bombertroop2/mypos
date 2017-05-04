class AddUniqueIndexToPurchaseOrderDetails < ActiveRecord::Migration[5.0]
  def change
    add_index :purchase_order_details, [:purchase_order_product_id, :size_id, :color_id], unique: true, name: "index_pod_on_purchase_order_product_id_size_id_color_id"
  end
end
