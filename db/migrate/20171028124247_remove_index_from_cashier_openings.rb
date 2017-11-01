class RemoveIndexFromCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    remove_index :cashier_openings, name: :idx_cashier_openings_warehouse_id_station_opened_by_open_date
    add_index :cashier_openings, [:warehouse_id, :station, :shift, :open_date], unique: true, name: "idx_cashier_openings_on_warehouse_id_station_shift_open_date"
  end
end
