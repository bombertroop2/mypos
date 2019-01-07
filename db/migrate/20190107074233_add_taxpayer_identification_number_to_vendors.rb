class AddTaxpayerIdentificationNumberToVendors < ActiveRecord::Migration[5.0]
  def change
    add_column :vendors, :taxpayer_identification_number, :string
  end
end
