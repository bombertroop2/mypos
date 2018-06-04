class AddWarehouseIdToConsignmentSales < ActiveRecord::Migration[5.0]
  def change
    add_reference :consignment_sales, :warehouse, foreign_key: true
  end
end
