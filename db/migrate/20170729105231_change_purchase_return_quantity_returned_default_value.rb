class ChangePurchaseReturnQuantityReturnedDefaultValue < ActiveRecord::Migration[5.0]
  def change
    change_column_default :stock_movement_transactions, :purchase_return_quantity_returned, 0
  end
end
