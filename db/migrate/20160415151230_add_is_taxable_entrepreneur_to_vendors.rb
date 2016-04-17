class AddIsTaxableEntrepreneurToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :is_taxable_entrepreneur, :boolean
  end
end
