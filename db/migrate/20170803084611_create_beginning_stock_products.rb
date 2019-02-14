class CreateBeginningStockProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :beginning_stock_products do |t|
      t.integer :beginning_stock_month_id, index: true
      t.references :product, foreign_key: true

      t.timestamps
    end
  end
end
