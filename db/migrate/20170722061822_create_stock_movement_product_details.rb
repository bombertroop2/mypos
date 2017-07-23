class CreateStockMovementProductDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :stock_movement_product_details do |t|
      t.integer :stock_movement_product_id
      t.references :color, index: true
      t.references :size, foreign_key: true
      t.integer :beginning_stock
      t.integer :purchase_order_quantity_received
      t.integer :purchase_return_quantity_returned
      t.integer :delivery_order_quantity_received
      t.integer :delivery_order_quantity_delivered
      t.integer :stock_return_quantity_returned
      t.integer :stock_transfer_quantity_received
      t.integer :stock_transfer_quantity_delivered
      t.integer :ending_stock

      t.timestamps
    end
    add_foreign_key :stock_movement_product_details, :stock_movement_products, column: :stock_movement_product_id
    add_foreign_key :stock_movement_product_details, :common_fields, column: :color_id
  end
end
