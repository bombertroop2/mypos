class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.string :code
      t.string :name
      t.datetime :start_date_time
      t.datetime :end_date_time
      t.boolean :apply_to_all_items

      t.timestamps
    end
    add_index :events, :code, unique: true
  end
end
