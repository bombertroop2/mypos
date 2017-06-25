class DropTableMessages < ActiveRecord::Migration[5.0]
  def change
    drop_table :messages if ActiveRecord::Base.connection.table_exists? 'messages'
  end
end
