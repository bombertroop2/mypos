class RemoveVendorIdFromPurchaseReturns < ActiveRecord::Migration
  def change
    remove_column :purchase_returns, :vendor_id, :integer
  end
end
