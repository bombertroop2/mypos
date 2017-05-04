class AddUniqueIndexToDirectPurchaseDetails < ActiveRecord::Migration[5.0]
  def change
    add_index :direct_purchase_details, [:direct_purchase_product_id, :size_id, :color_id], unique: true, name: "index_dpd_on_dpp_id_and_size_id_and_color_id"
  end
end
