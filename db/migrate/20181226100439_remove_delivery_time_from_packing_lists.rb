class RemoveDeliveryTimeFromPackingLists < ActiveRecord::Migration[5.0]
  def change
    remove_column :packing_lists, :delivery_time, :integer
  end
end
