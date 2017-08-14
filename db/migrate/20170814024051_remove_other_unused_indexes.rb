class RemoveOtherUnusedIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :order_booking_product_items, :order_booking_product_id if index_exists?(:order_booking_product_items, :order_booking_product_id)
    remove_index :shipment_products, :order_booking_product_id if index_exists?(:shipment_products, :order_booking_product_id)
    remove_index :shipment_product_items, :order_booking_product_item_id if index_exists?(:shipment_product_items, :order_booking_product_item_id)
    remove_index :stock_mutation_product_items, name: :index_smpi_on_stock_mutation_product_id
    remove_index :stock_movement_warehouses, :stock_movement_month_id if index_exists?(:stock_movement_warehouses, :stock_movement_month_id)
    remove_index :stock_movement_products, :product_id if index_exists?(:stock_movement_products, :product_id)
    remove_index :stock_movement_product_details, :color_id if index_exists?(:stock_movement_product_details, :color_id)
    remove_index :stock_movement_product_details, name: :index_smpd_on_stock_movement_product_id
    remove_index :listing_stocks, :warehouse_id if index_exists?(:listing_stocks, :warehouse_id)
    remove_index :listing_stock_product_details, :listing_stock_id if index_exists?(:listing_stock_product_details, :listing_stock_id)
  end
end
