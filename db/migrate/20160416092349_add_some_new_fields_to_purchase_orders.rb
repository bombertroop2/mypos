class AddSomeNewFieldsToPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :value_added_tax, :string
    add_column :purchase_orders, :is_taxable_entrepreneur, :boolean
  end
end
