class AddDueDateToAccountPayableCouriers < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payable_couriers, :due_date, :date
  end
end
