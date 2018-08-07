class ChangeJournalColumnTypeFromIntegerToDecimal < ActiveRecord::Migration[5.0]
  def change
      change_column :journals, :gross, :decimal
      change_column :journals, :gross_after_discount, :decimal
      change_column :journals, :discount, :decimal
      change_column :journals, :ppn, :decimal
      change_column :journals, :nett, :decimal
  end
end
