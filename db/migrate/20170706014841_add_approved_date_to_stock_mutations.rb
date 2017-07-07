class AddApprovedDateToStockMutations < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_mutations, :approved_date, :date
  end
end
