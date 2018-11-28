class RenameColumnPaymentStatusOfPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    rename_column :purchase_orders, :payment_status, :invoice_status
  end
end
