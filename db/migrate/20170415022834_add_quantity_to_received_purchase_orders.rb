class AddQuantityToReceivedPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :received_purchase_orders, :quantity, :integer
  end
end
