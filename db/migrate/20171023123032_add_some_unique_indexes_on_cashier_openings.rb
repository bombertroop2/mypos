class AddSomeUniqueIndexesOnCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    add_index :cashier_openings, [:warehouse_id, :opened_by, :open_date], unique: true, name: "index_cashier_openings_on_warehouse_id_opened_by_open_date"
    add_index :cashier_openings, [:warehouse_id, :station, :opened_by, :open_date], unique: true, name: "idx_cashier_openings_warehouse_id_station_opened_by_open_date"
  end
end
