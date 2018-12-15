class AddStatusBackToCouriers < ActiveRecord::Migration[5.0]
  def change
    add_column :couriers, :status, :string
  end
end
