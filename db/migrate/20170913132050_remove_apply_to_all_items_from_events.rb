class RemoveApplyToAllItemsFromEvents < ActiveRecord::Migration[5.0]
  def change
    remove_column :events, :apply_to_all_items, :boolean
  end
end
