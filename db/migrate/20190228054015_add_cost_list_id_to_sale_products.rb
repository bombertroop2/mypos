class AddCostListIdToSaleProducts < ActiveRecord::Migration[5.0]
  def change
    add_reference :sale_products, :cost_list, foreign_key: true
  end
end
