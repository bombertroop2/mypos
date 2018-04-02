class AddSomeFieldsToCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    add_column :cashier_openings, :net_sales, :decimal
    add_column :cashier_openings, :gross_sales, :decimal
    add_column :cashier_openings, :cash_payment, :decimal
    add_column :cashier_openings, :card_payment, :decimal
    add_column :cashier_openings, :debit_card_payment, :decimal
    add_column :cashier_openings, :credit_card_payment, :decimal
    add_column :cashier_openings, :total_quantity, :integer
  end
end
