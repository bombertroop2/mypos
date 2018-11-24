class RemoveSomeUnusedAdjusmentIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :adjustment_products, name: :index_adjustment_products_on_adjustment_id
    remove_index :adjustment_product_details, name: :index_adjustment_product_details_on_adjustment_product_id
  end
end
