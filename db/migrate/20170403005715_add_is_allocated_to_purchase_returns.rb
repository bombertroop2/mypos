class AddIsAllocatedToPurchaseReturns < ActiveRecord::Migration[5.0]
  def change
    add_column :purchase_returns, :is_allocated, :boolean, default: false
  end
end
