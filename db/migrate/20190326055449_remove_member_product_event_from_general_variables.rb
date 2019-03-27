class RemoveMemberProductEventFromGeneralVariables < ActiveRecord::Migration[5.0]
  def change
    remove_column :general_variables, :member_product_event, :boolean
  end
end
