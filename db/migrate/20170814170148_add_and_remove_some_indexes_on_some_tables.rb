class AddAndRemoveSomeIndexesOnSomeTables < ActiveRecord::Migration[5.0]
  def change
    add_index :available_menus, [:active, :name]
    remove_index :cost_lists, :product_id if index_exists?(:cost_lists, :product_id)
    remove_index :account_payable_purchases, name: :index_account_payable_purchases_on_purchase_id_and_type if index_exists?(:account_payable_purchases, [:purchase_id, :purchase_type], name: "index_account_payable_purchases_on_purchase_id_and_type")
    remove_index :direct_purchase_products, :direct_purchase_id if index_exists?(:direct_purchase_products, :direct_purchase_id)
    remove_index :direct_purchase_details, :direct_purchase_product_id if index_exists?(:direct_purchase_details, :direct_purchase_product_id)
    remove_index :listing_stock_transactions, name: :index_lst_on_listing_stock_product_detail_id if index_exists?(:listing_stock_transactions, :listing_stock_product_detail_id, name: "index_lst_on_listing_stock_product_detail_id")
    remove_index :product_details, :size_id if index_exists?(:product_details, :size_id)
    remove_index :purchase_order_products, :purchase_order_id if index_exists?(:purchase_order_products, :purchase_order_id)
    remove_index :purchase_order_details, :purchase_order_product_id if index_exists?(:purchase_order_details, :purchase_order_product_id)
    remove_index :purchase_return_products, :purchase_return_id if index_exists?(:purchase_return_products, :purchase_return_id)
    remove_index :purchase_return_items, :purchase_return_product_id if index_exists?(:purchase_return_items, :purchase_return_product_id)
    remove_index :received_purchase_order_products, :received_purchase_order_id if index_exists?(:received_purchase_order_products, :received_purchase_order_id)
    remove_index :received_purchase_order_items, :received_purchase_order_product_id if index_exists?(:received_purchase_order_items, :received_purchase_order_product_id)
    remove_index :roles, :name if index_exists?(:roles, :name)
    remove_index :sizes, :size_group_id if index_exists?(:sizes, :size_group_id)
    remove_index :stock_details, :stock_product_id if index_exists?(:stock_details, :stock_product_id)
    remove_index :stock_movement_transactions, :stock_movement_product_detail_id if index_exists?(:stock_movement_transactions, :stock_movement_product_detail_id)
    remove_index :stock_products, :stock_id if index_exists?(:stock_products, :stock_id)
  end
end
