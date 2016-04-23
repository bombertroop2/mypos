class AddDirectPurchaseDetailIdToReceivedPurchaseOrderItems < ActiveRecord::Migration
  def change
    add_column :received_purchase_order_items, :direct_purchase_detail_id, :integer
  end
end
