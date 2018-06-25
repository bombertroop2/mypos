class AddIsReceiveDateChangedToStockMutations < ActiveRecord::Migration[5.0]
  def change
    add_column :stock_mutations, :is_receive_date_changed, :boolean, default: false
  end
end
