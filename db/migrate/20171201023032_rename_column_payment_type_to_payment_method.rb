class RenameColumnPaymentTypeToPaymentMethod < ActiveRecord::Migration[5.0]
  def change
    rename_column :sales, :payment_type, :payment_method
  end
end
