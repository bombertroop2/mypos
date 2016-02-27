class RemoveSomeFieldsFromPurchaseReturnItems < ActiveRecord::Migration
  def change
    remove_column :purchase_return_items, :size_id, :integer
    remove_column :purchase_return_items, :color_id, :integer
  end
end
