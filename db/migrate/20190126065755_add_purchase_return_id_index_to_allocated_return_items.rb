class AddPurchaseReturnIdIndexToAllocatedReturnItems < ActiveRecord::Migration[5.0]
  def change
    add_index :allocated_return_items, :purchase_return_id, :unique => true
  end
end
