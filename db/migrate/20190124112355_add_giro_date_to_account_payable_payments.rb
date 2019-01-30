class AddGiroDateToAccountPayablePayments < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payable_payments, :giro_date, :date, default:nil
  end
end
