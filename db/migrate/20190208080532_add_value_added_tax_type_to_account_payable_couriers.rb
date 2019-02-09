class AddValueAddedTaxTypeToAccountPayableCouriers < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payable_couriers, :value_added_tax_type, :string
  end
end
