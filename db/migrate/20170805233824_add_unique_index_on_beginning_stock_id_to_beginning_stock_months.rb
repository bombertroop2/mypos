class AddUniqueIndexOnBeginningStockIdToBeginningStockMonths < ActiveRecord::Migration[5.0]
  def change
    if ActiveRecord::Base.connection.table_exists? 'beginning_stock_months'
      add_index :beginning_stock_months, :beginning_stock_id, unique: true, name: "unique_index_beginning_stock_months_on_beginning_stock_id"
    end
  end
end
