class RemoveBeginningStockMonthIdFromBeginningStockProducts < ActiveRecord::Migration[5.0]
  def change
    remove_column :beginning_stock_products, :beginning_stock_month_id, :integer if column_exists?(:beginning_stock_products, :beginning_stock_month_id) # code ini dicopy ke file migrasi sebelumnya, jadi kode ini sebenarnya tidak butuh dipisah
  end
end
