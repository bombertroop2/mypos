class CreateEventProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :event_products do |t|
      t.references :event_warehouse, foreign_key: true
      t.references :product, foreign_key: true

      t.timestamps
    end
  end
end
