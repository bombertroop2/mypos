class CreateAccountPayablePurchases < ActiveRecord::Migration[5.0]
  def change
    create_table :account_payable_purchases do |t|
      t.integer :purchase_id
      t.string :purchase_type, limit: 20
      t.references :account_payable, foreign_key: true

      t.timestamps
    end
    add_index :account_payable_purchases, [:purchase_id, :purchase_type], name: "index_account_payable_purchases_on_purchase_id_and_type"
    add_index :account_payable_purchases, :account_payable_id rescue nil
  end
end
