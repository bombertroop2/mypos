class AddSomeFieldsToStocks < ActiveRecord::Migration
  def change
    add_reference :stocks, :warehouse, index: true, foreign_key: true
  end
end
