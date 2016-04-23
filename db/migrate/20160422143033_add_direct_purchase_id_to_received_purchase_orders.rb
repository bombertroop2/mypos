class AddDirectPurchaseIdToReceivedPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :received_purchase_orders, :direct_purchase_id, :integer
  end
end
