class CreatePurchaseReturnProducts < ActiveRecord::Migration
  def change
    create_table :purchase_return_products do |t|
      t.references :product, index: true, foreign_key: true
      t.references :purchase_return, index: true, foreign_key: true
      t.integer :total_quantity

      t.timestamps null: false
    end
  end
end
