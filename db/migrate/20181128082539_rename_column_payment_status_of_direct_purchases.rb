class RenameColumnPaymentStatusOfDirectPurchases < ActiveRecord::Migration[5.0]
  def change
    rename_column :direct_purchases, :payment_status, :invoice_status
  end
end
