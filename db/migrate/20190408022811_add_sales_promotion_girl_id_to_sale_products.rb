class AddSalesPromotionGirlIdToSaleProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :sale_products, :product_spg_id, :integer
    add_index :sale_products, :product_spg_id
  end
end
