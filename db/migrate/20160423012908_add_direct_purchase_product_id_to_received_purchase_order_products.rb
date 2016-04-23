class AddDirectPurchaseProductIdToReceivedPurchaseOrderProducts < ActiveRecord::Migration
  def change
    add_column :received_purchase_order_products, :direct_purchase_product_id, :integer
  end
end
