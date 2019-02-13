class RemoveBankAccountNumberFromAccountPayableCourierPayments < ActiveRecord::Migration[5.0]
  def change
    remove_column :account_payable_courier_payments, :bank_account_number, :string
  end
end
