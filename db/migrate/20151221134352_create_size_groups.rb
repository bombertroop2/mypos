class CreateSizeGroups < ActiveRecord::Migration
  def change
    create_table :size_groups do |t|
      t.string :code
      t.text :description

      t.timestamps null: false
    end
  end
end
