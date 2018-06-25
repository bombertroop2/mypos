class AddIsReceiveDateChangedToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :is_receive_date_changed, :boolean, default: false
  end
end
