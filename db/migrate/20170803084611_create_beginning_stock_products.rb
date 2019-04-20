class CreateBeginningStockProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :beginning_stock_products do |t|
      if ActiveRecord::Base.connection.table_exists? 'beginning_stock_months'
        t.references :beginning_stock_month, foreign_key: true
      end
      t.references :product, foreign_key: true

      t.timestamps
    end
  end
end
