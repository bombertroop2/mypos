class CreateAccountsReceivablePaymentInvoices < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts_receivable_payment_invoices do |t|
      t.references :accounts_receivable_payment, foreign_key: true, index: false
      t.references :accounts_receivable_invoice, foreign_key: true, index: false
      t.decimal :amount

      t.timestamps
    end
    
    add_index :accounts_receivable_payment_invoices, :accounts_receivable_invoice_id, name: "index_arpi_on_accounts_receivable_invoice_id"
    add_index :accounts_receivable_payment_invoices, [:accounts_receivable_payment_id, :accounts_receivable_invoice_id], unique: true, name: "index_arpi_on_ar_payment_id_and_ar_invoice_id"
  end
end
