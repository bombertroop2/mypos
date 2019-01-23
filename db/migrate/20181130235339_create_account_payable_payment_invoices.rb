class CreateAccountPayablePaymentInvoices < ActiveRecord::Migration[5.0]
  def change
    create_table :account_payable_payment_invoices do |t|
      t.references :account_payable_payment, foreign_key: true, index: { name: 'index_appi_on_account_payable_payment_id' }
      t.references :account_payable, foreign_key: true

      t.timestamps
    end
    remove_index :account_payable_payment_invoices, :account_payable_payment_id
    add_index :account_payable_payment_invoices, [:account_payable_payment_id, :account_payable_id], unique: true, name: "index_appi_on_account_payable_payment_id_and_account_payable_id"
  end
end
