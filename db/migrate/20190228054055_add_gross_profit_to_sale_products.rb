class AddGrossProfitToSaleProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :sale_products, :gross_profit, :decimal
  end
end
