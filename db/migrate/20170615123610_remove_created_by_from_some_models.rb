class RemoveCreatedByFromSomeModels < ActiveRecord::Migration[5.0]
  def change
    remove_column :purchase_orders, :created_by, :integer
    remove_column :purchase_returns, :created_by, :integer
    remove_column :account_payables, :created_by, :integer
    remove_column :order_bookings, :created_by, :integer
    remove_column :shipments, :created_by, :integer
  end
end
