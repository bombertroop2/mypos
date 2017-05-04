class AddUniqueIndexToAccountPayablePurchases < ActiveRecord::Migration[5.0]
  def change
    add_index :account_payable_purchases, [:purchase_id, :purchase_type, :account_payable_id], unique: true, name: "index_app_on_purchase_id_purchase_type_account_payable_id"
  end
end
