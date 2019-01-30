class AddAccountPayablePaymentInvoiceIdToAllocatedReturnItems < ActiveRecord::Migration[5.0]
  def change
    add_reference :allocated_return_items, :account_payable_payment_invoice, foreign_key: true, index: false
    add_index :allocated_return_items, :account_payable_payment_invoice_id, name: "index_ari_on_account_payable_payment_invoice_id"
  end
end
