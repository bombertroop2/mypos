class CreatePriceLists < ActiveRecord::Migration
  def change
    create_table :price_lists do |t|
      t.date :effective_date
      t.decimal :price
      t.references :product_detail, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
