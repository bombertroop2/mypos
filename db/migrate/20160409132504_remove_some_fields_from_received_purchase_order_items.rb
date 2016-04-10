class RemoveSomeFieldsFromReceivedPurchaseOrderItems < ActiveRecord::Migration
  def change
    remove_reference :received_purchase_order_items, :size, index: true, foreign_key: true
    remove_column :received_purchase_order_items, :color_id, :integer
  end
end
