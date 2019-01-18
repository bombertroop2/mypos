class CreateAccountPayablePayments < ActiveRecord::Migration[5.0]
  def change
    create_table :account_payable_payments do |t|
      t.date :payment_date
      t.decimal :amount

      t.timestamps
    end
  end
end
