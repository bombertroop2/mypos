class AddIsPackedUpToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :is_packed_up, :boolean, default: false
  end
end
