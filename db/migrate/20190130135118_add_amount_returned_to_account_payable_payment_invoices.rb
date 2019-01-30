class AddAmountReturnedToAccountPayablePaymentInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payable_payment_invoices, :amount_returned, :decimal, default: 0
  end
end
