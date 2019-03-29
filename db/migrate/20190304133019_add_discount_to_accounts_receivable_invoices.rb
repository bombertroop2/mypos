class AddDiscountToAccountsReceivableInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts_receivable_invoices, :discount, :float, default: 0
  end
end
