class RemoveCourierIdFromStockMutations < ActiveRecord::Migration[5.0]
  def change
    remove_column :stock_mutations, :courier_id, :integer
  end
end
