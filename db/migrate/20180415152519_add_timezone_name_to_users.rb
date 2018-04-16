class AddTimezoneNameToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :timezone_name, :string
  end
end
