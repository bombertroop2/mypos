class AddPuchaseOrderDateToPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :purchase_order_date, :date
  end
end
