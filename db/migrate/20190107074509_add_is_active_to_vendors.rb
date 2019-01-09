class AddIsActiveToVendors < ActiveRecord::Migration[5.0]
  def change
    add_column :vendors, :is_active, :boolean, default: true
  end
end
