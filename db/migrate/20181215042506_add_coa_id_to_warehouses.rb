class AddCoaIdToWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_column :warehouses, :coa_id, :integer, index: true
  end
end
