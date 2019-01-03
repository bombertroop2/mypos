class AddCourierUnitIdToPackingLists < ActiveRecord::Migration[5.0]
  def change
    add_reference :packing_lists, :courier_unit, foreign_key: true
  end
end
