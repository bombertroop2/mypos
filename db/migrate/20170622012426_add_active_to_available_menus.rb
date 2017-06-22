class AddActiveToAvailableMenus < ActiveRecord::Migration[5.0]
  def change
    add_column :available_menus, :active, :boolean
  end
end
