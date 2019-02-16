class AddCityIdToPackingLists < ActiveRecord::Migration[5.0]
  def change
    add_reference :packing_lists, :city, foreign_key: true
  end
end
