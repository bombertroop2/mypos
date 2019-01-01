class AddEstimatedDeliveryTimeToWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_column :warehouses, :estimated_delivery_time, :integer
  end
end
