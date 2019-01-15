class AddSomeNewFieldsToAccountPayables < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payables, :vendor_invoice_number, :string
    add_column :account_payables, :vendor_invoice_date, :date
  end
end
