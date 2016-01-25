class AddIndexToSalesPromotionGirls < ActiveRecord::Migration
  def change
    add_index :sales_promotion_girls, :identifier, :unique => true
  end
end
