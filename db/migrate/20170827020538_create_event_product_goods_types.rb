class CreateEventProductGoodsTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :event_product_goods_types do |t|
      t.references :event, foreign_key: true
      t.references :goods_type, index: true

      t.timestamps
    end
    add_foreign_key :event_product_goods_types, :common_fields, column: :goods_type_id
  end
end
