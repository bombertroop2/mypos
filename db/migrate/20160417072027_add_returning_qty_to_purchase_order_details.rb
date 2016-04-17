class AddReturningQtyToPurchaseOrderDetails < ActiveRecord::Migration
  def change
    add_column :purchase_order_details, :returning_qty, :integer
  end
end
