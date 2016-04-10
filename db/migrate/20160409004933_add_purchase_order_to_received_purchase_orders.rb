class AddPurchaseOrderToReceivedPurchaseOrders < ActiveRecord::Migration
  def change
    add_reference :received_purchase_orders, :purchase_order, index: true, foreign_key: true
  end
end
