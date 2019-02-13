class CreateAccountPayableCourierPaymentInvoices < ActiveRecord::Migration[5.0]
  def change
    create_table :account_payable_courier_payment_invoices do |t|
      t.references :account_payable_courier_payment, foreign_key: true, index: false
      t.references :account_payable_courier, foreign_key: true, index: {name: "index_apcpi_on_account_payable_courier_id"}
      t.decimal :amount

      t.timestamps
    end
    add_index :account_payable_courier_payment_invoices, [:account_payable_courier_payment_id, :account_payable_courier_id], unique: true, name: "index_apcpi_on_apcp_id_and_account_payable_courier_id"
  end
end
