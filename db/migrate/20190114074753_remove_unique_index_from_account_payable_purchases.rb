class RemoveUniqueIndexFromAccountPayablePurchases < ActiveRecord::Migration[5.0]
  def change
    remove_index :account_payable_purchases, name: :index_app_on_purchase_id_purchase_type_account_payable_id
  end
end
