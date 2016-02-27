class CreatePurchaseReturnItems < ActiveRecord::Migration
  def change
    create_table :purchase_return_items do |t|
      t.references :purchase_return_product, index: true, foreign_key: true
      t.references :size, index: true, foreign_key: true
      t.references :color, index: true
      t.integer :quantity

      t.timestamps null: false
    end
    add_foreign_key :purchase_return_items, :common_fields, column: :color_id
  end
end
