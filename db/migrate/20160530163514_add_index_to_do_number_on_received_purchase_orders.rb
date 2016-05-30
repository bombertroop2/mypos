class AddIndexToDoNumberOnReceivedPurchaseOrders < ActiveRecord::Migration
  def change
    add_index :received_purchase_orders, :delivery_order_number, :unique => true
  end
end
