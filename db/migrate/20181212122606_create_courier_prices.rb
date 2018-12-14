class CreateCourierPrices < ActiveRecord::Migration[5.0]
  def change
    create_table :courier_prices do |t|
      t.references :courier, foreign_key: true, index: false
      t.references :city, foreign_key: true
      t.date :effective_date
      t.decimal :price
      t.string :price_type

      t.timestamps
    end
    add_index :courier_prices, [:courier_id, :city_id, :effective_date, :price_type], unique: true, name: "index_cp_on_courier_id_n_city_id_n_effective_date_n_price_type"
  end
end
