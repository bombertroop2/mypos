class RemoveViaFromCouriers < ActiveRecord::Migration[5.0]
  def change
    remove_column :couriers, :via, :string
  end
end
