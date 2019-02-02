class AddInvoiceStatusToReceivedPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :received_purchase_orders, :invoice_status, :string, default: ""
  end
end
