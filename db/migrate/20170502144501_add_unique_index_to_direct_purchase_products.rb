class AddUniqueIndexToDirectPurchaseProducts < ActiveRecord::Migration[5.0]
  def change
    add_index :direct_purchase_products, [:direct_purchase_id, :product_id], unique: true, name: "index_dpp_on_direct_purchase_id_and_product_id"
  end
end
