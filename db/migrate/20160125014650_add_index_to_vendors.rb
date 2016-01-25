class AddIndexToVendors < ActiveRecord::Migration
  def change
    add_index :vendors, :code, :unique => true
  end
end
