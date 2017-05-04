class AddUniqueIndexToAllocatedReturnItems < ActiveRecord::Migration[5.0]
  def change
    add_index :allocated_return_items, [:account_payable_id, :purchase_return_id], unique: true, name: "index_ari_on_account_payable_id_and_purchase_return_id"
  end
end
