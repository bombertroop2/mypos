class RemoveCostFromProductDetailHistories < ActiveRecord::Migration
  def change
    remove_column :product_detail_histories, :cost, :decimal if ActiveRecord::Base.connection.table_exists? 'product_detail_histories'
  end
end
