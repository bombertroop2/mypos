class AddNoteToPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :purchase_orders, :note, :text
  end
end
