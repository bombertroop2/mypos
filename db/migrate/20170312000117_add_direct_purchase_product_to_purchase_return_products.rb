class AddDirectPurchaseProductToPurchaseReturnProducts < ActiveRecord::Migration[5.0]
  def change
    add_reference :purchase_return_products, :direct_purchase_product, foreign_key: true
  end
end
