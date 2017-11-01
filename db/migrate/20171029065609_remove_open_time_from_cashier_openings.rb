class RemoveOpenTimeFromCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    remove_column :cashier_openings, :open_time, :datetime
  end
end
