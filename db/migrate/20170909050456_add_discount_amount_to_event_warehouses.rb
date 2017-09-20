class AddDiscountAmountToEventWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_column :event_warehouses, :discount_amount, :decimal
  end
end
