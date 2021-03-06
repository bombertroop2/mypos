class CreateCourierUnits < ActiveRecord::Migration[5.0]
  def change
    create_table :courier_units do |t|
      t.references :courier_way, foreign_key: true, index: false
      t.string :name

      t.timestamps
    end
    add_index :courier_units, [:courier_way_id, :name], unique: true
  end
end
