class AddDirectPurchaseToPurchaseReturns < ActiveRecord::Migration[5.0]
  def change
    add_reference :purchase_returns, :direct_purchase, foreign_key: true
  end
end
