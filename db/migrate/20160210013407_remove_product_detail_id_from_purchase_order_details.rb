class RemoveProductDetailIdFromPurchaseOrderDetails < ActiveRecord::Migration
  def change
    remove_column :purchase_order_details, :product_detail_id
  end
end
