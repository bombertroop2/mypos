class RemoveMinimumPurchaseAmountFromEvents < ActiveRecord::Migration[5.0]
  def change
    remove_column :events, :minimum_purchase_amount, :decimal
  end
end
