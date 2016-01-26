class AddIndexToPurchaseOrder < ActiveRecord::Migration
  def change
    add_index :purchase_orders, :number, :unique => true
  end
end
