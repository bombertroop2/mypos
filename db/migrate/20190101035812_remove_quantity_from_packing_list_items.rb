class RemoveQuantityFromPackingListItems < ActiveRecord::Migration[5.0]
  def change
    remove_column :packing_list_items, :quantity, :integer
  end
end
