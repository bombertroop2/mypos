class AddSalesReturnIdToSalesReturnProducts < ActiveRecord::Migration[5.0]
  def change
    add_reference :sales_return_products, :sales_return, foreign_key: true
  end
end
