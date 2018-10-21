class RemoveBeginningStockMonthIdFromBeginningStockProducts < ActiveRecord::Migration[5.0]
  def change
    remove_column :beginning_stock_products, :beginning_stock_month_id, :integer
  end
end
