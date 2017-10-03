class AddSelectDifferentProductsToEventWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_column :event_warehouses, :select_different_products, :boolean
  end
end
