class RemoveUnusedIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :product_colors, :product_id if index_exists?(:product_colors, :product_id)
    remove_index :accounts, name: :index_account_payable_purchases_on_purchase_id_and_type
    remove_index :allocated_return_items, :account_payable_id if index_exists?(:allocated_return_items, :account_payable_id)
    remove_index :order_booking_products, :order_booking_id if index_exists?(:order_booking_products, :order_booking_id)
  end
end
