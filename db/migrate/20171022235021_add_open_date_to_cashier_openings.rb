class AddOpenDateToCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    add_column :cashier_openings, :open_date, :date
  end
end
