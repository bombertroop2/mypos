class CreateCounterEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :counter_events do |t|
      t.string :code
      t.string :name
      t.datetime :start_time
      t.datetime :end_time
      t.float :first_discount
      t.float :second_discount
      t.decimal :special_price

      t.timestamps
    end
  end
end
