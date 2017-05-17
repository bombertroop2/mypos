class AddOriginWarehouseIdToOrderBookingProductItems < ActiveRecord::Migration[5.0]
  def change
    add_column :order_booking_product_items, :origin_warehouse_id, :integer
  end
end
