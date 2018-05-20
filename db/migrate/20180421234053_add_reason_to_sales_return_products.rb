class AddReasonToSalesReturnProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :sales_return_products, :reason, :string
  end
end
