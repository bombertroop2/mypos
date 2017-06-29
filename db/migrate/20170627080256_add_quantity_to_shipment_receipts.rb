class AddQuantityToShipmentReceipts < ActiveRecord::Migration[5.0]
  def change
    add_column :shipment_receipts, :quantity, :integer
  end
end
