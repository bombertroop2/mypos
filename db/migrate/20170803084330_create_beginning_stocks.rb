class CreateBeginningStocks < ActiveRecord::Migration[5.0]
  def change
    create_table :beginning_stocks do |t|
      t.integer :year
      t.references :warehouse, foreign_key: true

      t.timestamps
    end
  end
end
