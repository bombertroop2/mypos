class AddMemberProductEventToSales < ActiveRecord::Migration[5.0]
  def change
    add_column :sales, :member_product_event, :boolean
  end
end
