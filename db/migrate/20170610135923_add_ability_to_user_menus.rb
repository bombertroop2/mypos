class AddAbilityToUserMenus < ActiveRecord::Migration[5.0]
  def change
    add_column :user_menus, :ability, :integer
  end
end
