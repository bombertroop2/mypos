class AddUniqueIndexToShipmentDoNumber < ActiveRecord::Migration[5.0]
  def change
    add_index :shipments, :delivery_order_number, :unique => true
  end
end
