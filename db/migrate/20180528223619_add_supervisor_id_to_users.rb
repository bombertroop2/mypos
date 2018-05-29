class AddSupervisorIdToUsers < ActiveRecord::Migration[5.0]
  def change
    add_reference :users, :supervisor, foreign_key: true
    remove_index :users, name: :index_users_on_supervisor_id
    add_index :users, :supervisor_id, unique: true
  end
end
