class RemoveCourierCostFromStockMutations < ActiveRecord::Migration[5.0]
  def change
    remove_column :stock_mutations, :courier_cost, :decimal
  end
end
