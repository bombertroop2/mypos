class AddValueLimitToCustomers < ActiveRecord::Migration[5.0]
  def change
  	add_column :customers, :limit_value, :decimal
  end
end
