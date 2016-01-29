class CreatePurchaseOrderProducts < ActiveRecord::Migration
  def change
    create_table :purchase_order_products do |t|
      t.references :purchase_order, index: true, foreign_key: true
      t.references :product, index: true, foreign_key: true
      t.references :warehouse, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
