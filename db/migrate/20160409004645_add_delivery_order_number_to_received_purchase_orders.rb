class AddDeliveryOrderNumberToReceivedPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :received_purchase_orders, :delivery_order_number, :string
  end
end
