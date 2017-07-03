class RemoveTotalUnitPriceFromPurchaseOrderDetails < ActiveRecord::Migration[5.0]
  def change
    remove_column :purchase_order_details, :total_unit_price, :decimal
  end
end
