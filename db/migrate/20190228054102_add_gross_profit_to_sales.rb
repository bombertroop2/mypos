class AddGrossProfitToSales < ActiveRecord::Migration[5.0]
  def change
    add_column :sales, :gross_profit, :decimal
  end
end
