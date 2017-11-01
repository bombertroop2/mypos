class AddClosedAtToCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    add_column :cashier_openings, :closed_at, :datetime
  end
end
