class AddIsUsingDeliveryOrderToReceivedPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :received_purchase_orders, :is_using_delivery_order, :string
  end
end
