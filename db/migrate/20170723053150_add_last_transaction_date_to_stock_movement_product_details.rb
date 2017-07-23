class AddLastTransactionDateToStockMovementProductDetails < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_movement_product_details, :last_po_received_date, :date
  end
end
