class RemoveMinimumPurchaseAmountAndDiscountAmountFromEventWarehouses < ActiveRecord::Migration[5.0]
  def change
    remove_column :event_warehouses, :minimum_purchase_amount, :decimal
    remove_column :event_warehouses, :discount_amount, :decimal
  end
end
