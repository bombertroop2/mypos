class AddPaymentStatusToPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :purchase_orders, :payment_status, :string, default: ""
  end
end
