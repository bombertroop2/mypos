class AddShiftToCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    add_column :cashier_openings, :shift, :string, limit: 1
  end
end
