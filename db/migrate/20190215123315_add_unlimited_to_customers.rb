class AddUnlimitedToCustomers < ActiveRecord::Migration[5.0]
  def change
    add_column :customers, :unlimited, :boolean, default: false
  end
end
