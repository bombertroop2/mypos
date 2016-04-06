class RemoveWarehouseIdFromPurchaseOrderProducts < ActiveRecord::Migration
  def change
    remove_column :purchase_order_products, :warehouse_id, :integer
  end
end
