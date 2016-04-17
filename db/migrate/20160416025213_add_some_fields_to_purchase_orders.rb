class AddSomeFieldsToPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :first_discount, :float
    add_column :purchase_orders, :second_discount, :float
    add_column :purchase_orders, :price_discount, :decimal
  end
end
