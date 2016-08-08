class RemoveSomeFieldsFromReceivedPurchaseOrders < ActiveRecord::Migration
  def change
    remove_reference :received_purchase_orders, :purchase_order_product, index: true, foreign_key: true
    remove_reference :received_purchase_orders, :color, index: true, foreign_key: true rescue nil
  end
end
