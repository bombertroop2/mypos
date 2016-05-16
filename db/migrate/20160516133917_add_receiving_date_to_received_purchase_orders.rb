class AddReceivingDateToReceivedPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :received_purchase_orders, :receiving_date, :date
  end
end
