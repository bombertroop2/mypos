class AddUniqueIndexToSalesReturnProducts < ActiveRecord::Migration[5.0]
  def change
    add_index :sales_return_products, [:sale_product_id, :sales_return_id], unique: true, name: "index_srp_on_sale_product_id_and_sales_return_id"
  end
end
