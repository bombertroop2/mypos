class AddCreatedByToAccountPayables < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payables, :created_by, :integer
    add_index :account_payables, :created_by
  end
end
