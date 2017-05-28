class CreateCouriers < ActiveRecord::Migration[5.0]
  def change
    create_table :couriers do |t|
      t.string :code
      t.string :name
      t.string :via, limit: 4
      t.string :unit, limit: 8

      t.timestamps
    end
  end
end
