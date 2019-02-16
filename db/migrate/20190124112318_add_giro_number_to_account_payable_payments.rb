class AddGiroNumberToAccountPayablePayments < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payable_payments, :giro_number, :string, default: nil
  end
end
