class AddMemberProductDiscountToGeneralVariables < ActiveRecord::Migration[5.0]
  def change
    add_column :general_variables, :member_product_event, :boolean, default: true
  end
end
