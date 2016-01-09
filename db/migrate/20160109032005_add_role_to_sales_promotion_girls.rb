class AddRoleToSalesPromotionGirls < ActiveRecord::Migration
  def change
    add_column :sales_promotion_girls, :role, :string
  end
end
