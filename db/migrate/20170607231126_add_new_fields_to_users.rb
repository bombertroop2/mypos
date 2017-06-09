class AddNewFieldsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :name, :string
    add_column :users, :address, :text
    add_column :users, :phone, :string
    add_column :users, :mobile_phone, :string
    add_column :users, :gender, :string
    add_column :users, :role, :string
  end
end
