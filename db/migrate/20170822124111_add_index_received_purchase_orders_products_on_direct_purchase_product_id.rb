class AddIndexReceivedPurchaseOrdersProductsOnDirectPurchaseProductId < ActiveRecord::Migration[5.0]
  def change
    add_index :received_purchase_order_products, :direct_purchase_product_id, name: "index_rpop_on_direct_purchase_product_id"
  end
end
