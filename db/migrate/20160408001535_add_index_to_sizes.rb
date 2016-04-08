class AddIndexToSizes < ActiveRecord::Migration
  def change
    add_index :sizes, [:size_group_id, :size], :unique => true
  end
end
