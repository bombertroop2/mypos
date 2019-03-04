class AddCheckedToReceivedPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :received_purchase_orders, :checked, :boolean, default: false
  end
end
