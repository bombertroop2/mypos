class AddCostListToDirectPurchaseProducts < ActiveRecord::Migration
  def change
    add_reference :direct_purchase_products, :cost_list, index: true, foreign_key: true
  end
end
