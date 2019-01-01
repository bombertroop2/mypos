class RemoveUnusedFieldsFromPackingLists < ActiveRecord::Migration[5.0]
  def change
    remove_reference :packing_lists, :courier, foreign_key: true
    remove_reference :packing_lists, :courier_way, foreign_key: true
    remove_column :packing_lists, :courier_price_type, :string
    remove_reference :packing_lists, :city, foreign_key: true
  end
end
