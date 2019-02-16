class AddCourierCostToStockMutations < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_mutations, :courier_cost, :decimal
  end
end
