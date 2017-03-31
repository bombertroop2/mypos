class CreateAccountPayables < ActiveRecord::Migration[5.0]
  def change
    create_table :account_payables do |t|
      t.string :number
      t.string :payment_method
      t.decimal :amount_of_debt
      t.decimal :amount_paid
      t.decimal :amount_returned
      t.decimal :amount_to_be_paid
      t.string :giro_number
      t.date :giro_date
      t.decimal :remaining_debt
      t.date :payment_date
      t.references :vendor, foreign_key: true, index: true

      t.timestamps
    end
  end
end
