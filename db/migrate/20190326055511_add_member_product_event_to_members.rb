class AddMemberProductEventToMembers < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :member_product_event, :boolean, default: true
  end
end
