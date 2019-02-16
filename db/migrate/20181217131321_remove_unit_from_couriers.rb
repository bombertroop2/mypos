class RemoveUnitFromCouriers < ActiveRecord::Migration[5.0]
  def change
    remove_column :couriers, :unit, :string
  end
end
