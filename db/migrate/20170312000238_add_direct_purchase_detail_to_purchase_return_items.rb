class AddDirectPurchaseDetailToPurchaseReturnItems < ActiveRecord::Migration[5.0]
  def change
    add_reference :purchase_return_items, :direct_purchase_detail, foreign_key: true
  end
end
