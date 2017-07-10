class AddSomeMessagesFieldsToWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_column :warehouses, :first_message, :string
    add_column :warehouses, :second_message, :string
    add_column :warehouses, :third_message, :string
    add_column :warehouses, :fourth_message, :string
    add_column :warehouses, :fifth_message, :string
  end
end
