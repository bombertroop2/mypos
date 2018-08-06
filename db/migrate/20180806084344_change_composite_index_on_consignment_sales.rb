class ChangeCompositeIndexOnConsignmentSales < ActiveRecord::Migration[5.0]
  def change
    remove_index :consignment_sales, name: "index_cs_on_warehouse_id_and_no_sale_and_transaction_date"
    add_index :consignment_sales, [:warehouse_id, :transaction_date]
  end
end
