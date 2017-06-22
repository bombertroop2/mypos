class CreateAvailableMenus < ActiveRecord::Migration[5.0]
  def change
    create_table :available_menus do |t|
      t.string :name

      t.timestamps
    end
  end
end
