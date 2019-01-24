class RemovePaymentDateFromAccountPayables < ActiveRecord::Migration[5.0]
  def change
    remove_column :account_payables, :payment_date, :date
  end
end
