class AddTermsOfPaymentToCouriers < ActiveRecord::Migration[5.0]
  def change
    add_column :couriers, :terms_of_payment, :integer, default: 0
  end
end
