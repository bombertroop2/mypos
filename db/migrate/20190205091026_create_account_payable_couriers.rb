class CreateAccountPayableCouriers < ActiveRecord::Migration[5.0]
  def change
    create_table :account_payable_couriers do |t|
      t.string :number
      t.references :courier, foreign_key: true
      t.text :note
      t.decimal :total
      t.decimal :remaining_debt
      t.string :courier_invoice_number
      t.date :courier_invoice_date

      t.timestamps
    end
  end
end
