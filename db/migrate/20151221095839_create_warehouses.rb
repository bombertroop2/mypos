class CreateWarehouses < ActiveRecord::Migration
  def change
    create_table :warehouses do |t|
      t.string :code
      t.string :name
      t.text :address
      t.boolean :is_active
      t.references :supervisor, index: true, foreign_key: true
      t.references :region, index: true
      t.string :warehouse_type

      t.timestamps null: false
    end
    add_foreign_key :warehouses, :common_fields, column: :region_id
  end
end
