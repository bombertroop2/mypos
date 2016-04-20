class CreateDirectPurchaseDetails < ActiveRecord::Migration
  def change
    create_table :direct_purchase_details do |t|
      t.integer :quantity
      t.decimal :total_unit_price
      t.references :direct_purchase_product, index: true, foreign_key: true
      t.references :size, index: true, foreign_key: true
      t.references :color, index: true
      t.integer :returning_qty

      t.timestamps null: false
    end
    add_foreign_key :direct_purchase_details, :common_fields, column: :color_id
  end
end
