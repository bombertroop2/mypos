class AddSizeOrderToSizes < ActiveRecord::Migration[5.0]
  def change
    add_column :sizes, :size_order, :integer
  end
end
