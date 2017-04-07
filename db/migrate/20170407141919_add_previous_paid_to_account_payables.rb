class AddPreviousPaidToAccountPayables < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payables, :previous_paid, :decimal
  end
end
