class AddIndexReceivedPurchaseOrdersOnDirectPurchaseId < ActiveRecord::Migration[5.0]
  def change
    add_index :received_purchase_orders, :direct_purchase_id
  end
end
