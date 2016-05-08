class AddIndexThreeFieldsToProductDetails < ActiveRecord::Migration
  def change
    add_index :product_details, [:size_id, :product_id, :price_code_id], unique: true, name: "index_pd_on_size_id_and_product_id_and_price_code_id"
  end
end
