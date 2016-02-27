class CreatePurchaseReturns < ActiveRecord::Migration
  def change
    create_table :purchase_returns do |t|
      t.string :number
      t.references :vendor, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
