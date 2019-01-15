class AddTotalToAccountPayables < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payables, :total, :decimal, default: 0
  end
end
