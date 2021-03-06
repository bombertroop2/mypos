class CreateEventGeneralProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :event_general_products do |t|
      t.references :event, foreign_key: true
      t.references :product, foreign_key: true

      t.timestamps
    end
    add_index :event_general_products, [:event_id, :product_id], unique: true
  end
end
