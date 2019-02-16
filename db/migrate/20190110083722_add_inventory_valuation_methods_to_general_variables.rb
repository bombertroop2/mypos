class AddInventoryValuationMethodsToGeneralVariables < ActiveRecord::Migration[5.0]
  def change
    add_column :general_variables, :inventory_valuation_method, :string
  end
end
