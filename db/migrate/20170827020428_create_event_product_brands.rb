class CreateEventProductBrands < ActiveRecord::Migration[5.0]
  def change
    create_table :event_product_brands do |t|
      t.references :event, foreign_key: true
      t.references :brand, foreign_key: true

      t.timestamps
    end
  end
end
