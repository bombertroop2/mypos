class AddUniqueIndexOnWarehouseIdToBeginningStocks < ActiveRecord::Migration[5.0]
  def change
    if ActiveRecord::Base.connection.table_exists? 'beginning_stocks'
      add_index :beginning_stocks, :warehouse_id, unique: true, name: "unique_index_beginning_stocks_on_warehouse_id"
    end
  end
end
