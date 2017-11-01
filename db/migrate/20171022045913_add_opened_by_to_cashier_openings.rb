class AddOpenedByToCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    add_column :cashier_openings, :opened_by, :integer
    add_foreign_key :cashier_openings, :users, column: :opened_by
    add_index :cashier_openings, :opened_by
  end
end
