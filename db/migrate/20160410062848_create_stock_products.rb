class CreateStockProducts < ActiveRecord::Migration
  def change
    create_table :stock_products do |t|
      t.references :stock, index: true, foreign_key: true
      t.references :product, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
