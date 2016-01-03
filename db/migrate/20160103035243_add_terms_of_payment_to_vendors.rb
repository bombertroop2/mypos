class AddTermsOfPaymentToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :terms_of_payment, :integer
  end
end
