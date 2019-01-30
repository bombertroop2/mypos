class AddBankAccountNumberToAccountPayablePayments < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payable_payments, :bank_account_number, :string
  end
end
