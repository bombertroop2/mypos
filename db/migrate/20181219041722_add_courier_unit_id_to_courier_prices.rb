class AddCourierUnitIdToCourierPrices < ActiveRecord::Migration[5.0]
  def change
    add_reference :courier_prices, :courier_unit, foreign_key: true, index: false
    add_index :courier_prices, [:courier_unit_id, :city_id, :effective_date, :price_type], unique: true, name: "index_cp_on_courier_unit_id_city_id_effective_date_price_type"
  end
end
