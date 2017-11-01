class AddCashBalanceToCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    add_column :cashier_openings, :cash_balance, :decimal
  end
end
