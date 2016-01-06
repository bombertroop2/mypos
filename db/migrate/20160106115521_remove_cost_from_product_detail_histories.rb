class RemoveCostFromProductDetailHistories < ActiveRecord::Migration
  def change
    remove_column :product_detail_histories, :cost, :decimal
  end
end
