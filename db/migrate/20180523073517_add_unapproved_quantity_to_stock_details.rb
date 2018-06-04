class AddUnapprovedQuantityToStockDetails < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_details, :unapproved_quantity, :integer, default: 0
  end
end
