class AddPaymentMethodToAccountPayablePayments < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payable_payments, :payment_method, :string
  end
end
