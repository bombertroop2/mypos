class AddSalesReturnIdToSales < ActiveRecord::Migration[5.0]
  def change
    add_reference :sales, :sales_return, foreign_key: true
  end
end
