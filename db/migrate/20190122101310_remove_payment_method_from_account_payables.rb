class RemovePaymentMethodFromAccountPayables < ActiveRecord::Migration[5.0]
  def change
    remove_column :account_payables, :payment_method, :string
  end
end
