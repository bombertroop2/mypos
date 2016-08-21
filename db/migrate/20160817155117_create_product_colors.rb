class CreateProductColors < ActiveRecord::Migration[5.0]
  def change
    create_table :product_colors do |t|
      t.references :product, foreign_key: true
      t.references :color, index: true

      t.timestamps
    end
    add_foreign_key :product_colors, :common_fields, column: :color_id
  end
end
