class CreateEventProductGoodsTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :event_product_goods_types do |t|
      t.references :event, foreign_key: true
      t.references :goods_type, foreign_key: true

      t.timestamps
    end
  end
end
