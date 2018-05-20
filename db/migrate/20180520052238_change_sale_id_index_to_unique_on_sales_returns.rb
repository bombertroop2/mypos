class ChangeSaleIdIndexToUniqueOnSalesReturns < ActiveRecord::Migration[5.0]
  def change
    remove_index :sales_returns, name: :index_sales_returns_on_sale_id
    add_index :sales_returns, :sale_id, unique: true
  end
end
