class CreateEventProductBrands < ActiveRecord::Migration[5.0]
  def change
    create_table :event_product_brands do |t|
      t.references :event, foreign_key: true
      t.references :brand, index: true

      t.timestamps
    end
    add_foreign_key :event_product_brands, :common_fields, column: :brand_id
  end
end
