class AddPriceCodeIdToWarehouses < ActiveRecord::Migration
  def change
    add_reference :warehouses, :price_code, index: true, foreign_key: true
  end
end
