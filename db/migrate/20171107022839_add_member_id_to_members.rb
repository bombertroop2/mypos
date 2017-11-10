class AddMemberIdToMembers < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :member_id, :string, unique: true
    add_index :members, :member_id, unique: true
  end
end
