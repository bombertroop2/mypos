class RemoveSingleIndexFromSalesReturnProducts < ActiveRecord::Migration[5.0]
  def change
    remove_index :sales_return_products, name: :index_sales_return_products_on_sale_product_id
  end
end
