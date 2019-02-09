class AddAccountPayableCourierIdToPackingLists < ActiveRecord::Migration[5.0]
  def change
    add_reference :packing_lists, :account_payable_courier, foreign_key: true, default: nil
  end
end
