class AddPaymentStatusToDirectPurchases < ActiveRecord::Migration[5.0]
  def change
    add_column :direct_purchases, :payment_status, :string, default: ""
  end
end
