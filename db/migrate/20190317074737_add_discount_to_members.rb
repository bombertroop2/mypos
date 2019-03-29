class AddDiscountToMembers < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :discount, :float, default: 0
  end
end
