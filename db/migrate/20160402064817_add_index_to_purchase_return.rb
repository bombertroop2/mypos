class AddIndexToPurchaseReturn < ActiveRecord::Migration
  def change
    add_index :purchase_returns, :number, :unique => true
  end
end
