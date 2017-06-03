class ChangeAvailableQuantityColumnDefault < ActiveRecord::Migration[5.0]
  def change
    change_column_default :order_booking_product_items, :available_quantity, nil
  end
end
