class AddDueDateToAccountPayables < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payables, :due_date, :date
  end
end
