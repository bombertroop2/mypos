class CreateCashDisbursements < ActiveRecord::Migration[5.0]
  def change
    create_table :cash_disbursements do |t|
      t.references :cashier_opening, foreign_key: true
      t.string :description
      t.decimal :price

      t.timestamps
    end
  end
end
