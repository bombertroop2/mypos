class CreateStockMovementTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :stock_movement_transactions do |t|
      t.integer :stock_movement_product_detail_id
      t.integer :purchase_order_quantity_received, default: 0
      t.integer :purchase_return_quantity_returned, default: 0
      t.integer :delivery_order_quantity_received, default: 0
      t.integer :delivery_order_quantity_delivered, default: 0
      t.integer :stock_return_quantity_returned, default: 0
      t.integer :stock_transfer_quantity_received, default: 0
      t.integer :stock_transfer_quantity_delivered, default: 0
      t.integer :stock_return_quantity_received, default: 0
      t.date :transaction_date

      t.timestamps
    end
    
    add_foreign_key :stock_movement_transactions, :stock_movement_product_details, column: :stock_movement_product_detail_id
    add_index :stock_movement_transactions, :stock_movement_product_detail_id, name: "index_smt_on_stock_movement_product_detail_id"
  end
end
