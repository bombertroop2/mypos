class AddGiftEventIdAndGiftEventProductIdToSales < ActiveRecord::Migration[5.0]
  def change
    add_column :sales, :gift_event_id, :integer
    add_foreign_key :sales, :events, column: :gift_event_id
    add_index :sales, :gift_event_id
    add_column :sales, :gift_event_product_id, :integer
    add_foreign_key :sales, :stock_details, column: :gift_event_product_id
    add_index :sales, :gift_event_product_id
  end
end
