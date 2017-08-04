class CreateBeginningStockMonths < ActiveRecord::Migration[5.0]
  def change
    create_table :beginning_stock_months do |t|
      t.references :beginning_stock, foreign_key: true
      t.integer :month

      t.timestamps
    end
  end
end
