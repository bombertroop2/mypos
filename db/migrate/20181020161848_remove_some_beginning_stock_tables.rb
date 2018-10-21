class RemoveSomeBeginningStockTables < ActiveRecord::Migration[5.0]
  def change
    remove_column :beginning_stock_products, :beginning_stock_month_id, :integer if column_exists?(:beginning_stock_products, :beginning_stock_month_id) # harus remove column dulu agar bisa hapus table beginning_stock_months
    drop_table :beginning_stocks, force: :cascade if ActiveRecord::Base.connection.table_exists? 'beginning_stocks'
    drop_table :beginning_stock_months if ActiveRecord::Base.connection.table_exists? 'beginning_stock_months'
    drop_table :beginning_stock_product_details if ActiveRecord::Base.connection.table_exists? 'beginning_stock_product_details'
  end
end
