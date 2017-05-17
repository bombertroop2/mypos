class AddBookedQuantityToStockDetails < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_details, :booked_quantity, :integer, default: 0
  end
end
