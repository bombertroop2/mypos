class RemoveProductIdFromPurchaseReturnProducts < ActiveRecord::Migration
  def change
    remove_reference :purchase_return_products, :product, index: true, foreign_key: true
  end
end
