class CreateCourierWays < ActiveRecord::Migration[5.0]
  def change
    create_table :courier_ways do |t|
      t.references :courier, foreign_key: true, index: false
      t.string :name

      t.timestamps
    end
    add_index :courier_ways, [:courier_id, :name], unique: true
  end
end
