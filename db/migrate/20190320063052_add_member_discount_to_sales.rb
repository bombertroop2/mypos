class AddMemberDiscountToSales < ActiveRecord::Migration[5.0]
  def change
    add_column :sales, :member_discount, :float, default: 0
  end
end
