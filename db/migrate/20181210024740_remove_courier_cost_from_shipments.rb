class RemoveCourierCostFromShipments < ActiveRecord::Migration[5.0]
  def change
    remove_column :shipments, :courier_cost, :decimal
  end
end
