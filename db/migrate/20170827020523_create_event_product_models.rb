class CreateEventProductModels < ActiveRecord::Migration[5.0]
  def change
    create_table :event_product_models do |t|
      t.references :event, foreign_key: true
      t.references :model, foreign_key: true

      t.timestamps
    end
  end
end
