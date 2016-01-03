class AddGenderToSalesPromotionGirls < ActiveRecord::Migration
  def change
    add_column :sales_promotion_girls, :gender, :string
  end
end
