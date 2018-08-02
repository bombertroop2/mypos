class CreateTargets < ActiveRecord::Migration[5.0]
  def change
    create_table :targets do |t|
      t.references :warehouse, foreign_key: true
      t.integer :month
      t.integer :year
      t.decimal :target_value

      t.timestamps
    end
    add_index :targets, [:warehouse_id, :month, :year], unique: true
  end
end
