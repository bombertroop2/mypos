class CreateAccountPayablePurchasePartials < ActiveRecord::Migration[5.0]
  def change
    create_table :account_payable_purchase_partials do |t|
      t.references :account_payable, foreign_key: true
      t.references :received_purchase_order, foreign_key: true, index: false

      t.timestamps
    end
    add_index :account_payable_purchase_partials, :received_purchase_order_id, unique: true, name: "index_appp_on_received_purchase_order_id"
  end
end
