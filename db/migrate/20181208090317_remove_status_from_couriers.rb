class RemoveStatusFromCouriers < ActiveRecord::Migration[5.0]
  def change
    remove_column :couriers, :status, :string
  end
end
