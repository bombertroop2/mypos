class AddAmountToAccountPayablePaymentInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payable_payment_invoices, :amount, :decimal
  end
end
