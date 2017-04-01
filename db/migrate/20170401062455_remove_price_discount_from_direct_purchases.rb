class RemovePriceDiscountFromDirectPurchases < ActiveRecord::Migration[5.0]
  def change
    remove_column :direct_purchases, :price_discount, :decimal
  end
end
