class CreatePackingLists < ActiveRecord::Migration[5.0]
  def change
    create_table :packing_lists do |t|
      t.string :number
      t.string :status
      t.integer :delivery_time
      t.date :departure_date
      t.integer :total_quantity
      t.float :total_volume
      t.float :total_weight
      t.references :courier, foreign_key: true
      t.string :courier_price_type

      t.timestamps
    end
    add_index :packing_lists, :number, unique: true
  end
end
