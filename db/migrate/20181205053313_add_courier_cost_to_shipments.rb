class AddCourierCostToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :courier_cost, :decimal
  end
end
