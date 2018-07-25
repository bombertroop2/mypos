class AddCounterTypeToWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_column :warehouses, :counter_type, :string
  end
end
