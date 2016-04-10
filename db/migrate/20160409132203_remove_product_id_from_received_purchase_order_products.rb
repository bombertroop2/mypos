class RemoveProductIdFromReceivedPurchaseOrderProducts < ActiveRecord::Migration
  def change
    remove_reference :received_purchase_order_products, :product, index: true, foreign_key: true
  end
end
