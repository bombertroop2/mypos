class AddFreeProductIdToSaleProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :sale_products, :free_product_id, :integer
    add_foreign_key :sale_products, :stock_details, column: :free_product_id
    add_index :sale_products, :free_product_id
  end
end
