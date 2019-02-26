class RemoveUniqueIndexDoNumberOnRpo < ActiveRecord::Migration[5.0]
  def change
    remove_index :received_purchase_orders, :delivery_order_number
  end
end
