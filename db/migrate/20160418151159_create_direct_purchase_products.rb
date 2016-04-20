class CreateDirectPurchaseProducts < ActiveRecord::Migration
  def change
    create_table :direct_purchase_products do |t|
      t.references :direct_purchase, index: true, foreign_key: true
      t.references :product, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
