class AddUniqueIndexToPurchaseOrderProducts < ActiveRecord::Migration[5.0]
  def change
    add_index :purchase_order_products, [:purchase_order_id, :product_id], unique: true, name: "index_pop_on_purchase_order_id_and_product_id"
  end
end
