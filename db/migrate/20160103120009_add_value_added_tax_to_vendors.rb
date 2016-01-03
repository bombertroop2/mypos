class AddValueAddedTaxToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :value_added_tax, :string
  end
end
