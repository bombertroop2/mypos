class RemovePriceFromProductDetails < ActiveRecord::Migration
  def change
    remove_column :product_details, :price, :decimal
  end
end
