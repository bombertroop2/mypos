class RemoveAccountPayableIdFromAllocatedReturnItems < ActiveRecord::Migration[5.0]
  def change
    remove_column :allocated_return_items, :account_payable_id, :integer
  end
end
