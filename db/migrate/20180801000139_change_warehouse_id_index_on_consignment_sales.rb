class ChangeWarehouseIdIndexOnConsignmentSales < ActiveRecord::Migration[5.0]
  def change
    remove_index :consignment_sales, :warehouse_id if index_exists?(:consignment_sales, :warehouse_id)
    add_index :consignment_sales, [:warehouse_id, :no_sale, :transaction_date], name: "index_cs_on_warehouse_id_and_no_sale_and_transaction_date"
  end
end
