class CreateAdjustmentProductDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :adjustment_product_details do |t|
      t.references :adjustment_product, foreign_key: true
      t.integer :quantity, default: 0
      t.references :color, index: true
      t.references :size, foreign_key: true

      t.timestamps
    end
    add_index :adjustment_product_details, [:adjustment_product_id, :color_id, :size_id], unique: true, name: "index_apd_on_adjustment_product_id_and_color_id_and_size_id"
    add_foreign_key :adjustment_product_details, :common_fields, column: :color_id
  end
end
