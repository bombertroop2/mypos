class AddCostListToPurchaseOrderProducts < ActiveRecord::Migration
  def change
    add_reference :purchase_order_products, :cost_list, index: true, foreign_key: true
  end
end
