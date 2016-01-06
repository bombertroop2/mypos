class RemoveCostFromProductDetails < ActiveRecord::Migration
  def change
    remove_column :product_details, :cost, :decimal
  end
end
