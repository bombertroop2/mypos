class AddMemberProductDiscountToGeneralVariables < ActiveRecord::Migration[5.0]
  def change
    add_column :general_variables, :member_product_discount, :boolean, default: false
  end
end
