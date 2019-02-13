class CreateAccountPayableCourierPayments < ActiveRecord::Migration[5.0]
  def change
    create_table :account_payable_courier_payments do |t|
      t.date :payment_date
      t.decimal :amount
      t.string :payment_method
      t.string :number
      t.string :giro_number
      t.date :giro_date
      t.references :courier, foreign_key: true
      t.references :bank, foreign_key: true
      t.string :bank_account_number

      t.timestamps
    end
  end
end
