class AddNetAmountToPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :purchase_orders, :net_amount, :decimal
  end
end
