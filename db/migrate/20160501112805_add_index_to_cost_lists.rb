class AddIndexToCostLists < ActiveRecord::Migration
  def change
    add_index :cost_lists, [:product_id, :effective_date], :unique => true
  end
end
