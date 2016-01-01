class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :code
      t.text :description
      t.references :brand, index: true, foreign_key: true
      t.string :sex
      t.references :vendor, index: true, foreign_key: true
      t.string :target
      t.references :model, index: true, foreign_key: true
      t.references :goods_type, index: true, foreign_key: true
      t.string :image
      t.date :effective_date

      t.timestamps null: false
    end
  end
end
