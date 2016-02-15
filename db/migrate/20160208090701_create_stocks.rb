class CreateStocks < ActiveRecord::Migration
  def change
    create_table :stocks do |t|
      t.references :purchase_order_detail, index: true, foreign_key: true
      t.string :stock_type
      t.integer :quantity_on_hand

      t.timestamps null: false
    end
  end
end
