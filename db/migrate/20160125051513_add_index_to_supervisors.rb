class AddIndexToSupervisors < ActiveRecord::Migration
  def change
    change_column :supervisors, :email, :string, null: true
    add_index :supervisors, :code, :unique => true
    add_index :supervisors, :email, :unique => true
  end
end
