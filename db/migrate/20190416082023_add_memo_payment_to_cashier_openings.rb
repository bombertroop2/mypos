class AddMemoPaymentToCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    add_column :cashier_openings, :memo_payment, :decimal, default: 0
  end
end
