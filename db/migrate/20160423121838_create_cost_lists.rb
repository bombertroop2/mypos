class CreateCostLists < ActiveRecord::Migration
  def change
    create_table :cost_lists do |t|
      t.date :effective_date
      t.decimal :cost
      t.references :product, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
