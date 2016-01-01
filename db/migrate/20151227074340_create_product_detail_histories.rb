class CreateProductDetailHistories < ActiveRecord::Migration
  def change
    create_table :product_detail_histories do |t|
      t.decimal :cost
      t.decimal :price
      t.references :product_detail, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
