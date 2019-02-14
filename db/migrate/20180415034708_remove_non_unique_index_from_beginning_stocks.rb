class RemoveNonUniqueIndexFromBeginningStocks < ActiveRecord::Migration[5.0]
  def change
    remove_index :beginning_stocks, name: :index_beginning_stocks_on_warehouse_id if ActiveRecord::Base.connection.table_exists? 'beginning_stocks'
    remove_index :beginning_stock_months, name: :index_beginning_stock_months_on_beginning_stock_id if ActiveRecord::Base.connection.table_exists? 'beginning_stock_months'
    add_index :beginning_stock_products, [:beginning_stock_month_id, :product_id], :unique => true, name: "index_beginning_stock_products_on_bsm_id_and_product_id"
    add_index :beginning_stock_product_details, [:beginning_stock_product_id, :color_id, :size_id], :unique => true, name: "index_beginning_stock_product_details_on_bsp_color_size_id"
    add_index :fiscal_years, :year, :unique => true
    add_index :fiscal_months, [:fiscal_year_id, :month], :unique => true
    add_index :stock_mutation_products, [:stock_mutation_id, :product_id], :unique => true, name: "index_stock_mutation_products_on_stock_mutation_product_id"
  end
end
