class AddCourierPriceIdToPackingLists < ActiveRecord::Migration[5.0]
  def change
    add_reference :packing_lists, :courier_price, foreign_key: true
  end
end
