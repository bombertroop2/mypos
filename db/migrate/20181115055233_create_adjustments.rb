class CreateAdjustments < ActiveRecord::Migration[5.0]
  def change
    create_table :adjustments do |t|
      t.references :warehouse, foreign_key: true
      t.string :adj_type
      t.date :adj_date
      t.integer :quantity, default: 0

      t.timestamps
    end
  end
end
