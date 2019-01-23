class AddNewUniqueIndexToAccountPayablePurchases < ActiveRecord::Migration[5.0]
  def change
    add_index :account_payable_purchases, [:purchase_id, :purchase_type], unique: true, name: "index_app_on_purchase_id_and_purchase_type"
  end
end
