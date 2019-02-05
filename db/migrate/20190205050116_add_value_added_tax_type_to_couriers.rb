class AddValueAddedTaxTypeToCouriers < ActiveRecord::Migration[5.0]
  def change
    add_column :couriers, :value_added_tax_type, :string, default: ""
  end
end
