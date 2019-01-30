class AddNumberToAccountPayablePayments < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payable_payments, :number, :string
  end
end
