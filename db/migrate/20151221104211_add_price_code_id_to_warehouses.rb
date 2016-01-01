class AddPriceCodeIdToWarehouses < ActiveRecord::Migration
  def change
    add_reference :warehouses, :price_code, index: true
    add_foreign_key :warehouses, :common_fields, column: :price_code_id
  end
end
