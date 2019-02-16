class AddTaxpayerIdentificationNumberAddressToVendors < ActiveRecord::Migration[5.0]
  def change
    add_column :vendors, :taxpayer_identification_number_address, :text
  end
end
