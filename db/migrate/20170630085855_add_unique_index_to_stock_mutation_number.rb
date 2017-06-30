class AddUniqueIndexToStockMutationNumber < ActiveRecord::Migration[5.0]
  def change
    add_index :stock_mutations, :number, :unique => true
  end
end
