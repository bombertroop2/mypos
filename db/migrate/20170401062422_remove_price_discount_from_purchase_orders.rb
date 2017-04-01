class RemovePriceDiscountFromPurchaseOrders < ActiveRecord::Migration[5.0]
  def change
    remove_column :purchase_orders, :price_discount, :decimal
  end
end
