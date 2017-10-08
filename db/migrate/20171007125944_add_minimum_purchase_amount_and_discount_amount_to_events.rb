class AddMinimumPurchaseAmountAndDiscountAmountToEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :minimum_purchase_amount, :decimal
    add_column :events, :discount_amount, :decimal
  end
end
