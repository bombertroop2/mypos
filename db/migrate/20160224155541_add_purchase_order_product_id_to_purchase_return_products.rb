class AddPurchaseOrderProductIdToPurchaseReturnProducts < ActiveRecord::Migration
  def change
    add_reference :purchase_return_products, :purchase_order_product, index: true, foreign_key: true
  end
end
