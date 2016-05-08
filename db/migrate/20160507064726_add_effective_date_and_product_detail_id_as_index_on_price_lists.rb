class AddEffectiveDateAndProductDetailIdAsIndexOnPriceLists < ActiveRecord::Migration
  def change
    add_index :price_lists, [:effective_date, :product_detail_id], unique: true
  end
end
