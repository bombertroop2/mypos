class CreateCommonFields < ActiveRecord::Migration
  def change
    create_table :common_fields do |t|
      t.string :name
      t.text :description
      t.string :type
      t.string :code

      t.timestamps null: false
    end
  end
end
