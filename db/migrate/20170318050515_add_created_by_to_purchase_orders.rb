class AddCreatedByToPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :purchase_orders, :created_by, :integer
    add_index :purchase_orders, :created_by
  end
end
