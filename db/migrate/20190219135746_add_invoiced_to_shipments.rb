class AddInvoicedToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :invoiced, :boolean, default: false
  end
end
