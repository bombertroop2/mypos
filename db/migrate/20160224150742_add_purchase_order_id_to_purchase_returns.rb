class AddPurchaseOrderIdToPurchaseReturns < ActiveRecord::Migration
  def change
    add_reference :purchase_returns, :purchase_order, index: true, foreign_key: true
  end
end
