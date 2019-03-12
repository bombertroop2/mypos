class CreateAccountsReceivablePayments < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts_receivable_payments do |t|
      t.date :payment_date
      t.decimal :amount
      t.string :payment_method
      t.string :number
      t.string :giro_number
      t.date :giro_date
      t.references :customer, foreign_key: true

      t.timestamps
    end
  end
end
