class CreateFiscalMonths < ActiveRecord::Migration[5.0]
  def change
    create_table :fiscal_months do |t|
      t.references :fiscal_year, foreign_key: true
      t.string :month
      t.string :status

      t.timestamps
    end
  end
end
