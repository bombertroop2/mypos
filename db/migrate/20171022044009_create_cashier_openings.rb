class CreateCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    create_table :cashier_openings do |t|
      t.datetime :open_time
      t.references :warehouse, foreign_key: true
      t.string :station, limit: 1
      t.decimal :beginning_cash

      t.timestamps
    end
  end
end
