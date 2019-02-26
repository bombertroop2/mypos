class AddTransactionNumberReceivedPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :received_purchase_orders, :transaction_number, :string
    add_index :received_purchase_orders, :transaction_number, :unique => true
  end
end
