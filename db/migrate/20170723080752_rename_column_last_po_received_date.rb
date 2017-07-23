class RenameColumnLastPoReceivedDate < ActiveRecord::Migration[5.0]
  def change
    rename_column :stock_movement_product_details, :last_po_received_date, :last_transaction_date
  end
end
