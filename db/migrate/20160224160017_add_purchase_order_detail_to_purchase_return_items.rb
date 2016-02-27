class AddPurchaseOrderDetailToPurchaseReturnItems < ActiveRecord::Migration
  def change
    add_reference :purchase_return_items, :purchase_order_detail, index: true, foreign_key: true
  end
end
