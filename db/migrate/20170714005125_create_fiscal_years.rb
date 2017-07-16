class CreateFiscalYears < ActiveRecord::Migration[5.0]
  def change
    create_table :fiscal_years do |t|
      t.integer :year

      t.timestamps
    end
  end
end
