class ChangeSalesReturnIdIndexToUniqueOnSales < ActiveRecord::Migration[5.0]
  def change    
    remove_index :sales, name: :index_sales_on_sales_return_id
    add_index :sales, :sales_return_id, unique: true
  end
end
