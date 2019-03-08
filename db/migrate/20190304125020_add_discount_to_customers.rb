class AddDiscountToCustomers < ActiveRecord::Migration[5.0]
  def change
    add_column :customers, :discount, :float, default: 0
  end
end
