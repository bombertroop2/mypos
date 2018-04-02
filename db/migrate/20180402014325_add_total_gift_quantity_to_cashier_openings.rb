class AddTotalGiftQuantityToCashierOpenings < ActiveRecord::Migration[5.0]
  def change
    add_column :cashier_openings, :total_gift_quantity, :integer
  end
end
