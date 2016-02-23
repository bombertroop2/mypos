class RemoveMeansOfPaymentFromPurchaseOrders < ActiveRecord::Migration
  def change
    remove_column :purchase_orders, :means_of_payment, :integer
  end
end
