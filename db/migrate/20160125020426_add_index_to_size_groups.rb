class AddIndexToSizeGroups < ActiveRecord::Migration
  def change
    add_index :size_groups, :code, :unique => true
  end
end
