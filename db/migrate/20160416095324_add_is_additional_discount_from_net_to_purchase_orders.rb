class AddIsAdditionalDiscountFromNetToPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :is_additional_disc_from_net, :boolean
  end
end
