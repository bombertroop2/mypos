class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :code
      t.text :description
      t.references :brand, index: true
      t.string :sex
      t.references :vendor, index: true, foreign_key: true
      t.string :target
      t.references :model, index: true
      t.references :goods_type, index: true
      t.string :image
      t.date :effective_date

      t.timestamps null: false
    end
    add_foreign_key :products, :common_fields, column: :brand_id
    add_foreign_key :products, :common_fields, column: :model_id
    add_foreign_key :products, :common_fields, column: :goods_type_id
  end
end
