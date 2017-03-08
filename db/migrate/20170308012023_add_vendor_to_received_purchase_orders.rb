class AddVendorToReceivedPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_reference :received_purchase_orders, :vendor, foreign_key: true
  end
end
