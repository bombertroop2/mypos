class DropUserAbilities < ActiveRecord::Migration[5.0]
  def change
    drop_table :user_abilities if ActiveRecord::Base.connection.table_exists? 'user_abilities'
  end
end
