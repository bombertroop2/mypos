class RemoveProductPriceCodeIdFromProductDetail < ActiveRecord::Migration[5.0]
  def change
    remove_column :product_details, :product_price_code_id, :integer
  end
end
