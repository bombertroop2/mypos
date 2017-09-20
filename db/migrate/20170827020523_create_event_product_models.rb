class CreateEventProductModels < ActiveRecord::Migration[5.0]
  def change
    create_table :event_product_models do |t|
      t.references :event, foreign_key: true
      t.references :model, index: true

      t.timestamps
    end
    add_foreign_key :event_product_models, :common_fields, column: :model_id
  end
end
