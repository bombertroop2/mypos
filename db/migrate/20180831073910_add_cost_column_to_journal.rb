class AddCostColumnToJournal < ActiveRecord::Migration[5.0]
  def change
    add_column :journals, :cost_gross_price, :integer
    add_column :journals, :cost_gross_after_discount, :integer
    add_column :journals, :cost_discount, :integer
    add_column :journals, :cost_ppn, :integer
    add_column :journals, :cost_nett, :integer
  end
end
