class RemovePurchaseReturnIdIndexFromAllocatedReturnItems < ActiveRecord::Migration[5.0]
  def change
    remove_index :allocated_return_items, :purchase_return_id
  end
end
