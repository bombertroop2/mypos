class CreateSales < ActiveRecord::Migration[5.0]
  def change
    create_table :sales do |t|
      t.references :member, foreign_key: true
      t.datetime :transaction_time
      t.references :bank, foreign_key: true
      t.string :payment_type
      t.decimal :total
      t.string :trace_number
      t.string :card_number
      t.decimal :cash
      t.decimal :change
      t.string :transaction_number
      t.references :cashier_opening, foreign_key: true

      t.timestamps
    end
    add_index :sales, :transaction_number, unique: true
  end
end
